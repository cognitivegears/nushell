# Helper functions
def get_api_key [passed_api_key?: string] {
    $passed_api_key | default $env.YOUTUBE_API_KEY
}

def extract_video_id [url: string] {
    $url | parse -r "v=(?<video_id>[^&]+)" | get video_id.0
}

def format_duration [iso_duration: string] {
    $iso_duration
    | str replace -r "PT" ""
    | str replace -r "H" "h "
    | str replace -r "M" "m "
    | str replace -r "S" "s"
}

def format_date [date_string: string, format: string] {
    $date_string | into datetime | format date $format
}

def handle_file_existence [
    dir: string,
    base_name: string,
    file_exists_action: string
] {
    mut full_path = ($dir | path join $base_name)

    if ($full_path | path exists) {
        if $file_exists_action == "skip" {
            return {
                status: "skip",
                path: $full_path
            }
        } else if $file_exists_action == "unique" {
            # Make filename unique by adding incrementing number
            mut i = 1
            while ($full_path | path exists) {
                let new_name = ($base_name | path parse).stem + $"-($i)." + ($base_name | path parse).extension
                $full_path = ($dir | path join $new_name)
                $i = $i + 1
            }
        }
        # If overwrite, we'll use the original path and just overwrite
    }

    {
        status: "write",
        path: $full_path
    }
}

def create_safe_filename [title: string, timestamp: string] {
    # First sanitize the title by removing invalid filename characters
    # Replace any sequence of non-alphanumeric chars with a single dash
    let safe_title = ($title
        | str replace -a -r "[^a-zA-Z0-9]+" "-"
        | str replace -a -r "^-|-$" "" # Remove leading/trailing dashes
    )

    # Ensure the filename isn't too long (max 200 chars for the title part)
    let truncated_title = if ($safe_title | str length) > 200 {
        $safe_title | str substring 0..200
    } else {
        $safe_title
    }

    # Return the sanitized filename with timestamp and extension
    $"($truncated_title)-($timestamp).md"
}

def get_youtube_metadata [url: string, passed_api_key?: string] {
    let api_key = get_api_key $passed_api_key
    let video_id = extract_video_id $url

    # Define API endpoint with appropriate parts
    let api_url = $"https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=($video_id)&key=($api_key)"

    # Make API request and parse response
    let response = (http get $api_url)

    # Check if items exist in the response
    if ($response.items | length) == 0 {
        return "No video found with that ID"
    }

    # Extract relevant metadata from the first item
    let video = $response.items.0
    let snippet = $video.snippet
    let statistics = $video.statistics
    let content_details = $video.contentDetails

    # Format and return the metadata as a record
    {
        title: $snippet.title,
        channel_name: $snippet.channelTitle,
        channel_id: $snippet.channelId,
        published_at: $snippet.publishedAt,
        description: $snippet.description,
        tags: ($snippet | get -i tags | default []),
        category_id: $snippet.categoryId,
        views: $statistics.viewCount,
        likes: $statistics.likeCount,
        comments: $statistics.commentCount,
        duration: $content_details.duration,
        definition: $content_details.definition
    }
}

export def youtube_metadata [url: string, passed_api_key?: string] {
    let metadata = (get_youtube_metadata $url $passed_api_key)

    # Format the duration and publish date
    let duration = format_duration $metadata.duration
    let published = format_date $metadata.published_at "%B %d, %Y"

    # Create a more readable output
    {
        "Video Title": $metadata.title,
        "Channel": $metadata.channel_name,
        "Published On": $published,
        "Duration": $duration,
        "Views": $metadata.views,
        "Likes": $metadata.likes,
        "Comments": $metadata.comments,
        "Definition": ($metadata.definition | str upcase)
    }
}

def generate_markdown_content [metadata: record, url: string] {
    let duration = format_duration $metadata.duration
    let published = format_date $metadata.published_at "%B %d, %Y"
    let date_formatted = format_date $metadata.published_at "%Y-%m-%d"
    let time_formatted = format_date $metadata.published_at "%Y-%m-%dT%H:%M:%S"
    let description_first_line = $metadata.description | lines | first

    $"---
tags: [youtube, video, summary]
title: ($metadata.title)
description: ($description_first_line)
date: ($date_formatted)
time: ($time_formatted)
---

# ($metadata.title)

**Channel:** ($metadata.channel_name)

**Published On:** ($published)

**Duration:** ($duration)

**Views:** ($metadata.views)

**Likes:** ($metadata.likes)

**Comments:** ($metadata.comments)

**URL:** ($url)

## Description

($metadata.description)

"
}

export def youtube_markdown [
    url: string,
    dirname: string,
    passed_api_key?: string,
    --file-exists-action: string = "skip",
    --fabric-path: string = "fabric"
] {
    let metadata = (get_youtube_metadata $url $passed_api_key)

    # Generate timestamp for unique filenames
    let timestamp = format_date $metadata.published_at "%Y%m%d%H%M%S"

    # Create filename and handle file existence
    let file_name = create_safe_filename $metadata.title $timestamp

    # Debug print to verify filename doesn't have spaces
    print $"DEBUG: Generated filename: '($file_name)'"

    # Ensure dirname exists
    if not ($dirname | path exists) {
        mkdir $dirname
    }

    # Double-check: explicitly sanitize filename before passing to handle_file_existence
    let safe_file_name = ($file_name | str replace -a " " "-")

    let file_result = handle_file_existence $dirname $safe_file_name $file_exists_action

    # Print path for debugging
    print $"DEBUG: Path being used: '($file_result.path)'"

    # If we're skipping this file, return early
    if $file_result.status == "skip" {
        return {
            "Status": "Skipped",
            "File Path": $file_result.path,
            "Title": $metadata.title,
            "Reason": "File already exists and file-exists-action is set to 'skip'"
        }
    }

    # Generate markdown content
    let markdown_header = generate_markdown_content $metadata $url

    # Only run the expensive fabric call if we're going to use the result
    let expanded_fabric_path = ($fabric_path | path expand)
    let summary = (^$expanded_fabric_path -y $url -sp extract_wisdom)
    let markdown = $"($markdown_header)\n\n($summary)"

    # Save the markdown output to file (with force flag for overwrite cases)
    # Explicitly use the sanitized path to ensure no spaces
    let final_path = ($dirname | path join $safe_file_name)
    $markdown | save --force $final_path

    # Return success information
    {
        "Status": "Success",
        "File Path": $final_path,
        "Title": $metadata.title,
        "Duration": (format_duration $metadata.duration)
    }
}

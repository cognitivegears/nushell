# Save this content to youtube.nu
export def get_youtube_metadata [url: string, passed_api_key?: string] {

    let api_key = if ($passed_api_key == null) {
        $env.YOUTUBE_API_KEY
    } else {
        $passed_api_key
    }

    # Extract video ID from URL
    let video_id = ($url | parse -r "v=(?<video_id>[^&]+)" | get video_id.0)
    
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
    
    # Format the duration (ISO 8601 format to human-readable)
    let duration = ($metadata.duration | str replace -r "PT" "" | str replace -r "H" "h " | str replace -r "M" "m " | str replace -r "S" "s")
    
    # Format publish date
    let published = ($metadata.published_at | into datetime | format date "%B %d, %Y")
    
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



export def youtube_markdown [
    url: string, 
    dirname: string, 
    passed_api_key?: string, 
    --file-exists-action: string = "skip"  # Options: "skip", "overwrite", "unique"
] {
    let metadata = (get_youtube_metadata $url $passed_api_key)
    
    # Make a variable with title safe for a filename with .md extension
    let titlename = ($metadata.title | str replace -r "[^a-zA-Z0-9]+" "-")
    
    # Format publish date and times
    let date_fomatted = ($metadata.published_at | into datetime | format date "%Y-%m-%d")
    let time_fomatted = ($metadata.published_at | into datetime | format date "%Y-%m-%dT%H:%M:%S")
    let timestamp = ($metadata.published_at | into datetime | format date "%s")
    
    # Generate the base file name
    let file_name = $"($titlename)-($timestamp).md"
    mut full_path = ($dirname | path join $file_name)
    
    # Handle file existence based on the specified action
    if ($full_path | path exists) {
        if $file_exists_action == "skip" {
            return {
                "Status": "Skipped",
                "File Path": $full_path,
                "Title": $metadata.title,
                "Reason": "File already exists and file-exists-action is set to 'skip'"
            }
        } else if $file_exists_action == "unique" {
            # See if the file already exists, and if so, make filename unique
            let i = 1
            while ($full_path | path exists) {
                let file_name = $"($titlename)-($timestamp)-($i).md"
                $full_path = ($dirname | path join $file_name)
                let i = $i + 1
            }
        }
        # If overwrite, we'll use the original path and just overwrite
    }
    
    # Format the duration (ISO 8601 format to human-readable)
    let duration = ($metadata.duration | str replace -r "PT" "" | str replace -r "H" "h " | str replace -r "M" "m " | str replace -r "S" "s")
    
    # Format publish date for display
    let published = ($metadata.published_at | into datetime | format date "%B %d, %Y")
    
    let description_first_line = $metadata.description | lines | first
    
    # Create a markdown output
    let markdown_header = $"---
tags: [youtube, video, summary]
title: ($metadata.title)
description: ($description_first_line)
date: ($date_fomatted)
time: ($time_fomatted)
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

    # Only run the expensive fabric call if we're going to use the result
    let summary = (fabric -y $url -sp extract_wisdom)
    let markdown = $"($markdown_header)\n\n($summary)"

    # Save the markdown output to file (with force flag for overwrite cases)
    $markdown | save --force $full_path

    {
        "Status": "Success",
        "File Path": $full_path,
        "Title": $metadata.title,
        "Duration": $duration
    }
}

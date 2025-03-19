#!/usr/bin/env nu

# A wrapper script for youtube_markdown function from youtube.nu
# Usage: nu youtube_generate_markdown.nu <url> <dirname> [api_key] [--file-exists-action <action>]

use ./youtube.nu [youtube_markdown]

def print_help [] {
    print $"
Youtube Markdown Generator
=========================

Generates a markdown file with metadata and summary for a YouTube video.

Usage:
  youtube_generate_markdown.nu [options] <url> <dirname> [api_key]

Arguments:
  url              YouTube video URL
  dirname          Directory to save the markdown file
  api_key          Optional YouTube API key (defaults to $env.YOUTUBE_API_KEY)

Options:
  -h, --help                  Show this help message
  --file-exists-action <action>  What to do when file exists: \"skip\" (skip),
                              \"overwrite\", or \"unique\"

Examples:
  youtube_generate_markdown.nu https://www.youtube.com/watch?v=dQw4w9WgXcQ ~/notes
  youtube_generate_markdown.nu --file-exists-action unique https://youtu.be/dQw4w9WgXcQ ~/notes
"
    exit 0
}

def main [
    url?: string                           # YouTube video URL
    dirname?: string                       # Directory to save markdown file
    api_key?: string                       # Optional YouTube API key (defaults to $env.YOUTUBE_API_KEY)
    --file-exists-action: string = "skip"  # What to do when file exists: "skip", "overwrite", or "unique"
    -h                                     # Show help
    --help                                 # Show help
] {
    # Show help if requested or if required arguments are missing
    if $h or $help or ($url == null) or ($dirname == null) {
        print_help
    }

    youtube_markdown $url $dirname $api_key --file-exists-action $file_exists_action
}

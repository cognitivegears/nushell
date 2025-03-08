# Nu Scripts

A collection of personal [Nushell](https://www.nushell.sh/) scripts for various automation tasks.

## About Nushell

[Nushell](https://www.nushell.sh/) is a modern shell written in Rust that brings a structured approach to command-line interfaces. It treats data as structured objects rather than plain text, making it powerful for data manipulation.

## Available Scripts

### youtube.nu

This script provides commands for fetching and formatting YouTube video metadata using the YouTube API. It can also generate markdown summaries of YouTube videos using the Fabric AI tool.

#### Requirements

- Nushell
- YouTube API key (set as `$env.YOUTUBE_API_KEY` or pass directly to functions)
- [Fabric AI](https://github.com/danielmiessler/fabric) for the `youtube_markdown` function

#### Available Functions

1. **get_youtube_metadata**
   
   ```nushell
   get_youtube_metadata [url: string, passed_api_key?: string]
   ```
   
   Returns raw metadata about a YouTube video as a structured record.

2. **youtube_metadata**
   
   ```nushell
   youtube_metadata [url: string, passed_api_key?: string]
   ```
   
   Returns formatted, human-readable metadata about a YouTube video.

3. **youtube_markdown**
   
   ```nushell
   youtube_markdown [url: string, dirname: string, passed_api_key?: string, --file-exists-action: string]
   ```
   
   Generates a markdown file with video information and a summary created by Fabric AI. Saves the file in the specified directory.
   
   The `--file-exists-action` parameter supports three options:
   - `skip` (default): Skip if a file already exists
   - `overwrite`: Overwrite existing files
   - `unique`: Create a unique filename by adding a number suffix

#### Usage Examples

```nushell
# Load the script
use youtube.nu

# Get formatted metadata for a video
youtube_metadata "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Generate a markdown summary of a video
youtube_markdown "https://www.youtube.com/watch?v=dQw4w9WgXcQ" "~/Documents/video_notes"

# Generate with a custom API key and unique filenames
youtube_markdown "https://www.youtube.com/watch?v=dQw4w9WgXcQ" "~/Documents/video_notes" "YOUR_API_KEY" --file-exists-action unique
```

### youtube_generate_markdown.nu

A standalone executable wrapper script for the `youtube_markdown` function that can be run directly.

#### Usage

```nushell
# Basic usage
nu youtube_generate_markdown.nu "https://www.youtube.com/watch?v=dQw4w9WgXcQ" "~/Documents/video_notes"

# With options
nu youtube_generate_markdown.nu --file-exists-action unique "https://www.youtube.com/watch?v=dQw4w9WgXcQ" "~/Documents/video_notes"

# Show help
nu youtube_generate_markdown.nu -h
```

#### Help Information

Run `nu youtube_generate_markdown.nu -h` to see the complete help information, including:
- Command syntax
- Available options
- Usage examples

#### Setting up the YouTube API Key

1. Create a project in the [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the YouTube Data API v3
3. Create an API key
4. Set the API key in your Nushell environment:

```nushell
$env.YOUTUBE_API_KEY = "your_api_key_here"
```

Or add it to your Nushell config file for persistence.

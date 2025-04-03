#!/usr/bin/env nu

# Nushell script to check for and apply updates for various package managers.

# Function to display a prominent header message
def display-header [message: string] {

    let term_width = (term size).columns
    # Calculate padding more explicitly
    let msg_len = ($message | str length)
    let total_padding = $term_width - $msg_len
    # Ensure padding isn't negative if message is too long
    let padding_calc = if $total_padding < 0 { 0 } else { $total_padding / 2 }
    # Round the padding amount
    let padding = ($padding_calc | math round | into int)
    # Construct strings using different approach
    mut pad_str = ""
    for i in 0..($padding | into int) {
        $pad_str = $pad_str + " "
    }
    let header_line = $pad_str + $message # Simple string concatenation
    mut separator_line = ""
    for i in 0..($term_width | into int) {
        $separator_line = $separator_line + "-"
    }
    print $header_line
    print $separator_line
}

# --- Update Functions ---
def update-brew [] {
    display-header "Updating Homebrew"
    print "Updating brew repository..."
    ^brew update
    print "Upgrading installed formulae..."
    ^brew upgrade
    print "Upgrading installed casks..."
    ^brew upgrade --casks
    print "Cleaning up old versions..."
    ^brew cleanup
    print "Brew update complete."
}

def update-cargo [] {
    display-header "Updating Cargo Packages"
    print "Running cargo install-update..."
    # Run cargo install-update and capture errors
    ^cargo install-update -a
    if $env.LAST_EXIT_CODE != 0 {
        print $"Warning: Cargo update might have encountered issues."
    } else {
        print "Cargo packages updated."
    }
}

def update-volta [] {
    display-header "Updating Volta Packages"
    print "Getting list of volta packages..."

    # Run volta list and capture errors
    let version_list = (^volta list all --format plain|parse 'runtime node@{ver}.{rest}')
    let versions = $version_list | get ver


    let default = $version_list| reduce { |acc, version|
        if ($version | get rest | str contains "(default)") {
            return $version
        }
        return $acc
    }

    $version_list | each { |version|
        let major = ($version | get ver)

        print $"Updating volta package: ($major)"
        # Run volta install for each version
        ^volta install $"node@($major)"
    }

    if $default != "" {
        print $"Setting default volta version to: ($default|get ver)"
        # Set the default version
        ^volta install $"node@($default|get ver)"
    }

    print "Volta packages updated."
}

def update-mas [] {
    display-header "Updating Mac App Store Apps"
    print "Running mas upgrade..."
    # Run mas upgrade and capture errors
    ^mas upgrade
    if $env.LAST_EXIT_CODE != 0 {
        print $"Warning: Mac App Store update might have encountered issues."
    } else {
        print "Mac App Store apps updated."
    }
}

def update-npm [] {
    display-header "Updating NPM Global Packages"
    print "Running npm upgrade..."
    ^npm update -g
    if $env.LAST_EXIT_CODE != 0 {
        print $"Warning: NPM update might have encountered issues."
    } else {
        print "NPM global packages updated."
    }
}

# --- Main Update Logic ---
def update-all-packages [] {
    display-header "Updating System Packages"

    # Check and update brew
    if (which brew | is-not-empty) {
        update-brew
    } else {
        print "brew not found, skipping."
    }

    # Check and update cargo
    if (which cargo | is-not-empty) {
        update-cargo
    } else {
        print "cargo not found, skipping."
    }

    # Check and update cargo
    if (which volta | is-not-empty) {
        update-volta
    } else {
        print "volta not found, skipping."
    }

    # Check and update mas
    if (which mas | is-not-empty) {
        update-mas
    } else {
        print "mas (Mac App Store CLI) not found, skipping."
    }

    # Check and update npm
    if (which npm | is-not-empty) {
        update-npm
    } else {
        print "npm not found, skipping."
    }

    # Update the timestamp file
    try {
        touch ~/.lastupdate
        display-header "Finished Updating"
    } catch {
        # Print error message more safely
        let error_msg = $"Error: Failed to update timestamp file ~/.lastupdate - ($env.error | describe)"
        print $error_msg
    }
}

def to_days [duration: duration] {
    # Convert duration to days
    let days = ($duration | into int) / 86400000000000 | into int
    return $days
}

# --- Public Function for Checking Updates ---
export def check-system-updates [--force(-f)] {
    # This function replaces the previous "main" function
    let last_update_file = $"($env.HOME)/.lastupdate"
    let check_interval_days = 7

    print "Checking for updates..."

    if $force {
        print "Forcing update."
        update-all-packages
        return
    }

    if (not ($last_update_file | path exists)) {
        print "No last update timestamp found."
        update-all-packages
        return
    }

    # Check timestamp
    try {
        let last_update_time = ls $last_update_file | get modified | first
        let now = (date now)
        # Calculate duration and extract days directly
        let duration_diff = ($now - $last_update_time) | into duration
        let time_since_update = if ($duration_diff | describe) == "duration" {
             $duration_diff
        } else {
            # Handle potential error or default case, maybe assume 0 or raise error
            print "Warning: Could not calculate time difference accurately." # Print string directly
            0days
        }

        let days_since_update = to_days $time_since_update
        # Break the status message into multiple prints
        print "Packages updates last checked: "
        print $"($days_since_update) day\(s\) ago."

        if $days_since_update > $check_interval_days {
            print "Update interval exceeded, checking for updates."
            update-all-packages
        } else {
            print "Update check not yet needed."
        }
    } catch { |error|
        # Break the error message into multiple prints
        print "Error reading last update timestamp: "
        print $"Error ($error)"
        print "Proceeding with update check just in case."
        update-all-packages
    }
}

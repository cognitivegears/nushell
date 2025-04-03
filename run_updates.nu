#!/usr/bin/env nu

# Command-line wrapper for the check_updates.nu script

# Source the main script to get access to the functions
source ./check_updates.nu

def main [
    --help(-h),  # Show help
    --force(-f),  # Force update
] {
    # Show help if requested
    if $help {
        print $"run_updates.nu - A command-line wrapper for check_updates.nu"
        print $"Usage: nu run_updates.nu [--help]"
        print $"Options:"
        print $"  --help, -h  Show this help message"
        print $"  --force, -f Force update, defaults to false"
        print $""

        return
    }

    if $force {
        check-system-updates --force
    } else {
        check-system-updates
   }
}

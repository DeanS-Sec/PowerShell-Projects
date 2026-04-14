Startup Automation Script

Overview
This PowerShell script automates the startup of a daily workflow by launching Google Chrome with multiple profiles and predefined websites, along with opening Visual Studio Code. The goal is to streamline routine tasks and reduce manual setup time.

Features

Chrome Profile Automation
Launches multiple Chrome profiles (e.g., Personal and Work)
Opens predefined sets of websites for each profile
Starts each profile in a separate browser window

Application Launching
Automatically opens Visual Studio Code
Can be extended to launch additional applications

Execution Logging
Records script execution timestamps
Stores logs in a local file for tracking usage

Script Structure

Profiles
Defines Chrome profiles used for launching sessions

Website Lists
Maintains separate lists of URLs for each profile
Allows easy modification of startup environments

Core Function
Uses a reusable function to launch Chrome with a specified profile and list of websites

Logging Mechanism
Writes execution details to a log file for auditing and tracking

Usage

Run the Script
.\Startup-Automation.ps1

Execution Policy (if needed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Logging

The script logs each execution to a local file directory. Each entry includes a timestamp to help track when the script was run.

Customization

Chrome Profiles
Update profile names to match your Chrome configuration

Startup Websites
Modify or expand the lists of URLs assigned to each profile

Additional Applications
Add more Start-Process commands to launch other tools or programs

Example
Start-Process "notepad.exe"

Requirements

Windows Operating System
PowerShell 5.1 or later
Google Chrome installed
Visual Studio Code (optional)

Notes

Ensure chrome.exe and code.exe are available in the system PATH
Chrome profiles must already exist before running the script
Update file paths if using a different directory structure

Future Improvements

Add command-line parameters for profile selection
Enhance logging with error handling and execution details
Integrate with Windows Task Scheduler for automatic startup
Develop a graphical interface for easier configuration

Author

Dean Schauer

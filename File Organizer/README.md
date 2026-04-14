# Startup Workspace Script

## Overview
This PowerShell script automates the startup of a workspace by launching Google Chrome with specific user profiles and predefined websites.

The goal of this script is to eliminate repetitive daily setup tasks and create a consistent, efficient working environment.

---

## Features
- Launches Chrome with multiple user profiles
- Opens predefined websites automatically
- Supports both personal and work profiles
- Automates workspace setup on system startup
- Uses PowerShell arguments to control application behavior

---

## How It Works
The script uses PowerShell to:

1. Define lists of URLs for each profile
2. Build argument arrays for Chrome
3. Launch Chrome using `Start-Process`
4. Pass profile and URL arguments to Chrome
5. Open multiple tabs automatically

---

## Technologies Used
- PowerShell
- Google Chrome command-line arguments
- `Start-Process` for application launching

---

## Example Use Case
This script can be used to:
- Automatically open work-related websites at the start of the day
- Separate personal and work browsing environments
- Launch multiple Chrome profiles with different configurations
- Improve productivity by reducing manual setup steps

---

## Learning Objectives
This project helped develop:
- Understanding of PowerShell arguments and arrays
- Use of `Start-Process` for automation
- Working with multiple profiles and command-line options
- Structuring scripts for repeatable workflows

---

## Future Improvements
- Add support for launching additional applications (VS Code, Teams, etc.)
- Implement user selection (work vs personal mode)
- Add logging for script execution
- Integrate with Windows startup or scheduled tasks
- Expand into a full workspace automation tool


---

## Author
DeanS-Sec

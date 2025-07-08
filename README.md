# Windows-Search-Full-Index
A PowerShell script to prevent Windows from excluding folders to being indexed.

## Overview

Windows Search uses a background service to index files for faster lookup.  
For performance reasons, Microsoft has recently started to automatically exclude folders detected as repositories (such as Git or SVN) from indexing.
However, a bug causes not just the `.git` or `.svn` folders to be excluded, but their **parent folder** as well.  
This can be problematic for developers who use the repository folder as their working directory: any documents stored there will no longer be indexed and will not appear in Windows Search results.

## Workaround

Fortunately, there's a workaround. If a `.git` or `.svn` folder is **already present** in the list of excluded folders, then **the parent folder will no longer be automatically excluded**.
But manually adding each of these hidden folders to the exclusion list is tedious.  
This script was created to automate the process: it recursively scans the selected volume and adds **every folder starting with a dot (`.`)** to the Windows Search exclusion list.

---

## Usage Instructions

The inclusion/exclusion list is stored in a **protected key** of the Windows Registry.  
Therefore, running the script as Administrator is required — but not sufficient. You must also:

### 1. Grant Registry Permissions

In `regedit`, navigate to:

```
Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search\CrawlScopeManager\Windows\SystemIndex\WorkingSetRules
```

Right-click → **Permissions** → Grant **Full Control** to the **Administrators** group.

### 2. Configure Volume

Open `Windows-Search.ps1` in Notepad and edit the line:

```powershell
$volumeLetter = "E:\"
```

Change the drive letter if necessary.

### 3. Run the Script

Open **PowerShell as Administrator** and execute:

```powershell
.\Windows-Search.ps1
```

---

## Disclaimer

This script helps ensure your development files remain visible and searchable in Windows.

This script modifies sensitive keys of the Windows Registry and should be used with caution.  
Ensure you have a backup or system restore point before proceeding.  
Use at your own risk — the author is not responsible for any damage or data loss resulting from its use.

$baseGroupDatabasePath = "C:\Users\ycantin\Desktop\test\Database"

# Ensure the base path exists
if (-Not (Test-Path $baseGroupDatabasePath)) {
    Write-Host "Base path does not exist. Creating directory..."
    try {
        New-Item -Path $baseGroupDatabasePath -ItemType Directory -Force
        Write-Host "Directory created successfully at $baseGroupDatabasePath"
    } catch {
        Write-Host "Failed to create directory: $_"
    }
}

$userAges = @{}

function Add-User {
    param (
        [string]$Name,
        [string]$Group,
        [string]$NewSecurityLevel
    )

    $groupDatabasePath = Join-Path -Path $baseGroupDatabasePath -ChildPath "$Group.txt"
    
    if (-Not (Test-Path $groupDatabasePath)) {
        New-Item -Path $groupDatabasePath -ItemType File -Force
    }

    $existingUsers = Get-Content $groupDatabasePath -ErrorAction SilentlyContinue
    $userFound = $false
    $updatedContent = @()

    foreach ($line in $existingUsers) {
        if ($line -match "^$Name,") {
            $userFound = $true
            $parts = $line -split ","
            $updatedLine = "$($parts[0]),$($parts[1]),$NewSecurityLevel"
            $updatedContent += $updatedLine
            Write-Host "Updated security level for $Name in $Group."
        } else {
            $updatedContent += $line
        }
    }

    if (-not $userFound) {
        if ($userAges.ContainsKey($Name)) {
            $age = $userAges[$Name]
            $userInfo = "$Name,$age,$NewSecurityLevel"
            Add-Content -Path $groupDatabasePath -Value $userInfo
            Write-Host "$Name has been successfully added to the $Group database with the new security level."
        } else {
            Write-Host "$Name is not found in the $Group database and no age information is available."
        }
    } else {
        $updatedContent | Set-Content -Path $groupDatabasePath
    }
}

function Add-To-Groups {
    $users = Read-Host "Enter names of users you want to update or add, separated by a comma"
    $groups = Read-Host "Enter names of groups in which you wish to update or add users, separated by a comma"

    $user_array = $users -split ",\s*"
    $group_array = $groups -split ",\s*"

    foreach ($user in $user_array) {
        $user = $user.Trim()
        if (-not $userAges.ContainsKey($user)) {
            $age = Read-Host "Enter age of $user"
            $userAges[$user] = $age
        }
    }

    foreach ($group in $group_array) {
        $group = $group.Trim()
        Write-Host "Processing group: $group"
        
        foreach ($user in $user_array) {
            $user = $user.Trim()
            $newSecurityLevel = Read-Host "Enter security clearance for $user in $group"
            Add-User -Name $user -Group $group -NewSecurityLevel $newSecurityLevel
        }
    }
}

function remove-from-groups {
    $tempfile = [System.IO.Path]::GetTempFileName()  # Create a temporary file
    $users = Read-Host "Enter users to remove, separated by commas"
    $groups = Read-Host "Enter groups to remove users from, separated by commas"
    $reason = Read-Host "Please enter reason for deletion"

    $user_array = $users -split ",\s*"
    $group_array = $groups -split ",\s*"

    if ([string]::IsNullOrEmpty($groups))
    {
        $files = Get-ChildItem -Path $baseGroupDatabasePath -Filter *.txt
        foreach ($user in $user_array)
        {
            $user = $user.Trim()
            foreach ($file in $files)
            {
                $filePath = $file.FullName
                Set-Content -Path $tempfile -Value $null
                Get-Content $filePath |
                Where-Object { $_ -notmatch "^$user," } |
                Set-Content -Path $tempfile
                if ((Get-Item $tempfile).Length -lt (Get-Item $filePath).Length)
                {
                    Move-Item -Force $tempfile $filePath
                }
                else
                {
                    Remove-Item $tempfile -ErrorAction SilentlyContinue
                }
            }
        }
    }
    else
    {
        foreach ($user in $user_array)
        {
            $user = $user.Trim()
            foreach ($group in $group_array)
            {
                $groupFilePath = Join-Path -Path $baseGroupDatabasePath -ChildPath "$group.txt"
                if (Test-Path $groupFilePath) {
                    Set-Content -Path $tempfile -Value $null
                    Get-Content $groupFilePath |
                    Where-Object { $_ -notmatch "^$user," } |
                    Set-Content -Path $tempfile
                    if ((Get-Item $tempfile).Length -lt (Get-Item $groupFilePath).Length) 
                    {
                        Move-Item -Force $tempfile $groupFilePath
                    }
                    else
                    {
                        Remove-Item $tempfile -ErrorAction SilentlyContinue
                    }
                }
                else
                {
                    Write-Warning "Group file '$groupFilePath' does not exist."
                }
            }
        }
    }
    Remove-Item $tempfile -ErrorAction SilentlyContinue
}

function find-user
{
    $database = "C:\Users\ycantin\Desktop\test\Database"
    $files_present_in = @()
    $user = Read-Host "enter Name to find"
    if (-Not (Test-Path $database)) {
    Write-Host "The specified directory does not exist."
    exit}

    $files = Get-ChildItem -Path $database -Filter *.txt
    foreach($file in $files)
    {
        Write-Host "Searching in $file"
        $content = Get-Content -Path $file.FullName
        foreach($line in $content)
        {
            if ($line -match "\b$user\b")
            {
                $files_present_in += $file.FullName
            }
        }
    }
    if ($files_present_in.Count -gt 0)
    {
            Write-Host "'$user' found in the following files:"
            $files_present_in | ForEach-Object { Write-Host $_ }
    }
    else
    {
            Write-Host "User '$user' was not found in any files."
    }
}

function manager
{
$cmd = Read-Host "what kind of changes do you want to make today big boy?`nType --help to see options ;)"

if ($cmd -eq "add")
{
    Write-Host "adding users to groups"
    add-to-groups
}
elseif ($cmd -eq "rem")
{
    Write-Host "removing users from groups"
    remove-from-groups
}
elseif ($cmd -eq "--help")
{
    Write-Host "add -> adds members to groups`nrem -> removes members from groups [if no groups specified, user will be deleted from all existing groups]`nfind -> find where user is present`n"
}
elseif ($cmd -eq "find")
{
    Write-Host "finding user"
    find-user
}
else
{
    Write-Host "must've made a mistake buddyboy"
}
}
manager


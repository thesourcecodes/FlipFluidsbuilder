<#
Script to download FlipFluids Source Code (and everything we need to build/compile) and start building/compiling.
After build is done, a zip file is saved here: C:\FlipFluidstmp\flip_fluids_addon.zip. Once you copy this to a diffrent location you can delete: C:\FlipFluidstmp.
So to be clear no application is installed, no files or any other system modification is done to your system after running this script.

On most sytems the execution of powershell scripts is restricted, so we need to bypass this one time to excetuce this script.
More info: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.4

How to use: 
1. Download script or copy and past script(txt) as .ps1 file
2. Open powershell (or CMD) and typ (or copy paste): powershell -noexit -ExecutionPolicy Bypass -File "full path to file".
   Example: powershell -noexit -ExecutionPolicy Bypass -File "C:\Users\$env:username\Downloads\flipfluidsbuilder_v1.0.ps1"
3. Sit back and relax.

optimization: https://stackoverflow.com/questions/28682642/powershell-why-is-using-invoke-webrequest-much-slower-than-a-browser-download
#>

Write-Host "Starting Script..."

#make base folder to store all files:
$Folder = 'C:\FlipFluidstmp'
"Test to see if folder [$Folder] exists"
if (Test-Path -Path $Folder) {
    "Path exists!"
} else {
    Write-Host "creating folder: c:\FlipFluidstmp"
    New-Item -Path "c:\" -Name "FlipFluidstmp" -ItemType "directory" | Out-Null
}

# create array to store downlaod links and output
$files = @(
    @{
        Uri = "https://github.com/peazip/PeaZip/releases/download/9.8.0/peazip_portable-9.8.0.WINDOWS.zip"
        OutFile = 'C:\FlipFluidstmp\peazip.zip'
    }
    @{
        Uri = "https://netcologne.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z?viasf=1"
        OutFile = 'C:\FlipFluidstmp\x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z'
    },
    @{
        Uri = "https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-windows-x86_64.zip"
        OutFile = 'C:\FlipFluidstmp\cmake-3.30.2-windows-x86_64.zip'
    },
    @{
        Uri = "https://www.python.org/ftp/python/3.12.5/python-3.12.5-embed-amd64.zip"
        OutFile = 'C:\FlipFluidstmp\python-3.12.5-embed-amd64.zip'
    }
    @{
        Uri = "https://github.com/rlguy/Blender-FLIP-Fluids/archive/refs/heads/master.zip"
        OutFile = 'C:\FlipFluidstmp\Blender-FLIP-Fluids-master.zip'
    }
)

$jobs = @()

Write-Host ""
Write-Host "Downloads starting... creating powershell job for each download..."

#execute jobs
foreach ($file in $files) {
    $jobs += Start-Job -Name $file.OutFile -ScriptBlock {
        #disable Progressbar to speed up download
        $ProgressPreference = 'SilentlyContinue'
        $params = $using:file
        Invoke-WebRequest @params -UseBasicParsing
    }
}
Write-Host ""
Write-Host "Downloading.... this can take a while.. some mirros can be slow.. be patient. Progressbar is disabled to speed up downloads. You can track progress by opening folder: C:\FlipFluidstmp"
Write-Host "to check if filesizes starts growing"
write-host ""
write-host "After build is done, a zip file is saved here: C:\FlipFluidstmp\flip_fluids_addon.zip. Once you copy this to a diffrent location you can delete: C:\FlipFluidstmp.
So to be clear no application is installed, no files or any other system modification is done to your system after running this script."

#wait for jobs to finish before we contine
Wait-Job -Job $jobs | Out-Null
foreach ($job in $jobs) {
    Receive-Job -Job $job | Out-Null
}

#change dir to working folder
Write-Host "Change working directory to C:\FlipFluids..."
cd C:\FlipFluidstmp

# extract stuff

#extract peazip
Write-Host "Extracting peazip..."
Expand-Archive -Path peazip.zip -DestinationPath C:\FlipFluidstmp
$peazipmapname = Get-ChildItem -path "C:\FlipFluidstmp\peazip_p*" | select -expand name
Rename-Item -path "C:\FlipFluidstmp\$peazipmapname" -NewName "peazip"
Remove-Item -Path "C:\FlipFluidstmp\peazip.zip" -Force

# extract zips using 7z
Write-Host "Extracting all zip files..."
C:\FlipFluidstmp\peazip\res\bin\7z\7z.exe x *.zip -o*
# extract compiler mingw (.7z)
Write-Host "Extracting all 7z files..."
C:\FlipFluidstmp\peazip\res\bin\7z\7z.exe x x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z
#copy and rename item for make
Write-Host "copy and rename C:\FlipFluidstmp\mingw64\bin\mingw32-make.exe to make.exe..."
copy-item "C:\FlipFluidstmp\mingw64\bin\mingw32-make.exe" -Destination "C:\FlipFluidstmp\mingw64\bin\make.exe"

# set env vars
Write-Host "adding paths to env...(only in this powershell session)"
$env:Path += ';C:\FlipFluidstmp\mingw64\bin;C:\FlipFluidstmp\cmake-3.30.2-windows-x86_64\cmake-3.30.2-windows-x86_64\bin;C:\FlipFluidstmp\python-3.12.5-embed-amd64;C:\FlipFluidstmp\mingw64\bin;' 

# start compiling
Write-Host "Start compiling/building Flip Fluids..."
C:\FlipFluidstmp\python-3.12.5-embed-amd64\python.exe C:\FlipFluidstmp\Blender-FLIP-Fluids-master\Blender-FLIP-Fluids-master\build.py --clean

# Compress/zip build to zip file so we can import this in blender.
Write-host "Zipping build to: C:\FlipFluidstmp\flip_fluids_addon.zip"
$compress = @{
  Path = "C:\FlipFluidstmp\Blender-FLIP-Fluids-master\Blender-FLIP-Fluids-master\build\bl_flip_fluids\flip_fluids_addon"
  CompressionLevel = "Fastest"
  DestinationPath = "C:\FlipFluidstmp\flip_fluids_addon.zip"
}
Compress-Archive @compress
write-host ""
Write-Host "All done ! copy C:\FlipFluidstmp\flip_fluids_addon.zip to some other location and you can delete the folder: C:\FlipFluidstmp"

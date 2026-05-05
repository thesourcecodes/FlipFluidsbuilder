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

<#
Version:
18-08-2025: FlipFluidsBuilder_v1.1-1: change MingGW source to more updated version: v13, change Imath to v3.2.1
14-08-2025: FlipFluidsBuilder_v1.1: added new depenencies for flipfluids 1.8.4
05-05-2026: FlipFluidsBuilder_v1.1-1: update python to 3.14.4 (was 3.12.5)
05-05-2026: FlipFluidsBuilder_v1.1-1: add version control, instead of adding to $env:path start with clean path. This ensures the script works with supplied python version even if diffrent version(s) of pyhton is installed on system. Tested with fliplfuids 1.8.6
#>

# version control
$peazipver = "9.8.0"
$cmakever = "3.30.2"
$pythonver = "3.14.4"
$alembicver = "1.8.8"
$Imathver = "3.2.1"

Write-Host "####################################################################"
Write-Host "# Starting Script... FlipsFluidsBuilder_v1.1-1 for Flipfluids 1.8.6+ #"
Write-Host "####################################################################"

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
        Uri = "https://github.com/peazip/PeaZip/releases/download/$peazipver/peazip_portable-$peazipver.WINDOWS.zip"
        OutFile = "C:\FlipFluidstmp\peazip.zip"
    }
    @{
        Uri = "https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev0/x86_64-15.2.0-release-posix-seh-msvcrt-rt_v13-rev0.7z"
        OutFile = "C:\FlipFluidstmp\x86_64-15.2.0-release-posix-seh-msvcrt-rt_v13-rev0.7z"
    },
    @{
        Uri = "https://github.com/Kitware/CMake/releases/download/v$cmakever/cmake-$cmakever-windows-x86_64.zip"
        OutFile = "C:\FlipFluidstmp\cmake-$cmakever-windows-x86_64.zip"
    },
    @{
        Uri = "https://www.python.org/ftp/python/$pythonver/python-$pythonver-embed-amd64.zip"
        OutFile = "C:\FlipFluidstmp\python-$pythonver-embed-amd64.zip"
    }
    @{
        Uri = "https://github.com/rlguy/Blender-FLIP-Fluids/archive/refs/heads/master.zip"
        OutFile = "C:\FlipFluidstmp\Blender-FLIP-Fluids-master.zip"
    }
    @{
        Uri = "https://github.com/alembic/alembic/archive/refs/tags/$alembicver.zip"
        OutFile = "C:\FlipFluidstmp\alembic.zip"
    }
    @{
        Uri = "https://github.com/AcademySoftwareFoundation/Imath/releases/download/v$Imathver/Imath-$Imathver.tar.gz"
        OutFile = "C:\FlipFluidstmp\Imath.tar.gz"
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
C:\FlipFluidstmp\peazip\res\bin\7z\7z.exe x x86_64-15.2.0-release-posix-seh-msvcrt-rt_v13-rev0.7z
# extract Imath
C:\FlipFluidstmp\peazip\res\bin\7z\7z.exe x Imath.tar.gz
C:\FlipFluidstmp\peazip\res\bin\7z\7z.exe x Imath.tar -o*
# copy and rename item for make
Write-Host "copy and rename C:\FlipFluidstmp\mingw64\bin\mingw32-make.exe to make.exe..."
copy-item "C:\FlipFluidstmp\mingw64\bin\mingw32-make.exe" -Destination "C:\FlipFluidstmp\mingw64\bin\make.exe"

Write-Host "adding paths to env...(only in this powershell session)"
# backup current path
$pathbck = $env:Path
# create new path
$env:Path = "C:\FlipFluidstmp\mingw64\bin;C:\FlipFluidstmp\cmake-$cmakever-windows-x86_64\cmake-$cmakever-windows-x86_64\bin;C:\FlipFluidstmp\python-$pythonver-embed-amd64;C:\FlipFluidstmp\Imath\Imath-$Imathver\bin;C:\FlipFluidstmp\alembic\alembic-$alembicver\bin;" 

# compile imath:
Write-Host "Start compiling/building Imath and alembic..."
cd C:\FlipFluidstmp\Imath\Imath-$Imathver
cmake . -G "MinGW Makefiles" -DCMAKE_INSTALL_PREFIX=C:\FlipFluidstmp\Imath\Imath-$Imathver\
cmake --build . --target install --config Release

#compile alimbic
cd C:\FlipFluidstmp\alembic\alembic-$alembicver
#$env:Path += 'C:\FlipFluidstmp\imathlibs\bin;'
cmake . -G "MinGW Makefiles" -DCMAKE_INSTALL_PREFIX=C:\FlipFluidstmp\alembic\alembic-$alembicver\ Imath_DIR=C:\FlipFluidstmp\Imath\Imath-$Imathver\lib\cmake\Imath
cmake --build .

cd C:\FlipFluidstmp

# start compiling
Write-Host "Start compiling/building Flip Fluids..."
# define python exe and script
$pythonExe = "C:\FlipFluidstmp\python-$pythonver-embed-amd64\python.exe"
$buildScript = "C:\FlipFluidstmp\Blender-FLIP-Fluids-master\Blender-FLIP-Fluids-master\build.py"
# start build with parameter
& $pythonExe $buildScript --clean

# Compress/zip build to zip file so we can import this in blender.
Write-host "Zipping build to: C:\FlipFluidstmp\flip_fluids_addon.zip"
$compress = @{
  Path = "C:\FlipFluidstmp\Blender-FLIP-Fluids-master\Blender-FLIP-Fluids-master\build\bl_flip_fluids\flip_fluids_addon"
  CompressionLevel = "Fastest"
  DestinationPath = "C:\FlipFluidstmp\flip_fluids_addon.zip"
}
# restore path
$env:Path = $pathbck
Compress-Archive @compress
write-host ""
Write-Host "All done ! copy C:\FlipFluidstmp\flip_fluids_addon.zip to some other location and you can delete the folder: C:\FlipFluidstmp"

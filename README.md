# FlipFluidsbuilder
Powershell script to compile Flip Fluids

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

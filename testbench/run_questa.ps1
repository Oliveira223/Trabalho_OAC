# PowerShell helper to run the Questa DO file from the testbench folder
# Usage: Open PowerShell and run: .\run_questa.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

Write-Host "Compiling sources with vlog..."
vlog ..\src\cache_l1.v .\tb_cache_l1.v

Write-Host "Launching Questa (vsim) and running run_questa.do..."
# Run the DO file in Questa GUI
vsim -do .\run_questa.do

# If you prefer console (batch) execution uncomment below and comment the vsim -do line above
# vsim -c work.tb_cache_l1 -do "run -all; quit"

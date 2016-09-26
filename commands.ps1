<# 
.SYNOPSIS
  Generate a list of commands and metadata for company completion.
.DESCRIPTION
  Outputs data as a simple alist of form:
    (("command" "commandType" "helpUri" "synopsis")
     ...)
.PARAMETER outfile
  Path to output file, default is $PSScriptroot\commands.dat
.PARAMETER force
  If non-nil overwrites outfile.
#>

param($outfile = $null,
     $force = $null)

if ($outfile -eq $null) {
    $outfile = [System.IO.Path]::GetFullPath("$PSScriptroot\commands.dat")
} else {
    $outfile = [System.IO.Path]::GetFullPath("$outfile")
}

if (($force -eq $null) -and (Test-Path $outfile)) {
    Write-Error "$outfile already exists" -ErrorAction "Stop"
}

"(" | Out-File $outfile -Encoding utf8 -Force

Get-Command | 
  %{("(""$($_.Name)"" ""$($_.CommandType)"" ""$($_.HelpUri)"" " +
     """$(get-help $_ | %{$_.Synopsis})"")").
    Replace("`r`n", " ").Replace('\', '\\')} |
  ac $outfile

")" | ac $outfile

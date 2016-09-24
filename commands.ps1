param($outfile = $null,
     $force = $null)

# generate list of commands:
# (("command" "commandType" "helpUri" "synopsis") ... )

if ($outfile -eq $null) {
    $outfile = [System.IO.Path]::GetFullPath("$PSScriptroot\commands.dat")
} else {
    $outfile = [System.IO.Path]::GetFullPath("$outfile")
}

if (($force -eq $null) -and (Test-Path $outfile)) {
    Write-Error "$outfile already exists" -ErrorAction "Stop"
}

"(" | Out-file $outfile -Encoding utf8 -Force

get-command | 
  %{("(""$($_.Name)"" ""$($_.CommandType)"" ""$($_.HelpUri)"" " +
     """$(get-help $_ | %{$_.Synopsis})"")").
    Replace("`r`n", " ").Replace('\', '\\')} |
  ac $outfile

")" | ac $outfile

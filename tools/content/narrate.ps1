# Reads build/lectures/<id>/manifest.json and writes one WAV per segment with the
# Windows speech engine (System.Speech). Usage: narrate.ps1 [-Id ei-foundations] [-Rate -2]
param([string]$Id = '', [int]$Rate = -2)
Add-Type -AssemblyName System.Speech
$root = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'build\lectures'
$dirs = if ($Id) { @(Join-Path $root $Id) } else { Get-ChildItem $root -Directory | ForEach-Object FullName }
foreach ($d in $dirs) {
  $m = Get-Content (Join-Path $d 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $i = 0
  foreach ($s in $m.segments) {
    $wav = Join-Path $d ('seg{0:D2}.wav' -f $i)
    if (-not (Test-Path $wav)) {
      $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
      $synth.SelectVoice('Microsoft Zira Desktop')
      $synth.Rate = $Rate
      $synth.SetOutputToWaveFile($wav)
      $synth.Speak($s.narration)
      $synth.Dispose()
    }
    $i++
  }
  Write-Output ("narrated " + $m.id)
}

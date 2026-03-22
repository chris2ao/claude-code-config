# prompt-notify.ps1 — Plays a notification sound when Claude Code finishes
# its turn and needs user attention (permission prompt, question, etc.)
#
# How it works:
#   Uses the .NET System.Media.SystemSounds API to play the system "Asterisk"
#   sound — a soft, pleasant notification tone built into Windows.
#   Falls back to the console BEL character if that fails.
#
# Hook event: Stop (fires when Claude's turn ends and user input is needed)

try {
    # Play the Windows "Asterisk" system sound — a gentle notification tone.
    # Other options: Beep, Exclamation, Hand, Question
    [System.Media.SystemSounds]::Asterisk.Play()
} catch {
    # Fallback: send BEL character to the console (terminal bell)
    [Console]::Beep(800, 200)  # 800 Hz tone for 200ms — short and pleasant
}

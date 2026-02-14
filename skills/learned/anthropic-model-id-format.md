# Anthropic Model ID Format

## Pattern
Anthropic model IDs require exact date suffixes. The `-latest` alias does not exist for all models.

## Symptom
API call returns `404 {"type":"not_found_error","message":"model: claude-haiku-4-5-latest"}`.

## Root Cause
Code reviewers and documentation may suggest `-latest` model aliases, but these don't exist for all Anthropic models. Haiku specifically requires the full date suffix.

## Fix
Use exact model IDs with date suffixes:
- `claude-haiku-4-5-20251001` (correct)
- `claude-haiku-4-5-latest` (404 error)
- `claude-sonnet-4-5-20250929` (correct)
- `claude-opus-4-6` (correct, no date needed for Opus)

Always verify model IDs against the Anthropic API documentation before deploying.

## Category
api

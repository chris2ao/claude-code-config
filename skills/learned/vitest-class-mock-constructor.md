# Vitest Class-Based Factory Mock for SDK Constructors

## Pattern
When mocking an SDK that is instantiated with `new`, you cannot use arrow functions in `vi.mock` because arrow functions lack a `[[Construct]]` internal method.

## Symptom
```
TypeError: _Anthropic is not a constructor
```

## Root Cause
`vi.mocked(Anthropic).mockImplementation(() => ({ ... }))` fails because the arrow function replacement cannot be called with `new`.

## Fix
Use a class-based factory mock:
```typescript
const mockCreate = vi.fn();

vi.mock("@anthropic-ai/sdk", () => ({
  default: class MockAnthropic {
    messages = { create: mockCreate };
  },
}));
```

This works because `class` expressions have the `[[Construct]]` internal method and can be used with `new`.

## Applies To
Any SDK or library that exports a class to be instantiated (Anthropic, OpenAI, Stripe, AWS SDK, etc.).

## Category
testing

<!-- managed by claude-code-starter [pack:nextjs] -->
---
name: frontend-patterns
description: React/Next.js patterns for component architecture, hooks, state management, and API integration.
---

# Frontend Patterns

## Component Architecture
- Server Components by default (Next.js App Router)
- `"use client"` only when needed (interactivity, hooks, browser APIs)
- Collocate components with their routes

## State Management
- Server state: React Query / SWR
- Client state: Zustand (persist to localStorage for user preferences)
- Form state: React Hook Form + Zod validation

## API Integration
```typescript
// Centralized API client
const response = await apiClient.get<ResponseType>('/endpoint');

// React Query for server state
const { data, isLoading } = useQuery({
  queryKey: ['items', id],
  queryFn: () => apiClient.get(`/items/${id}`),
});
```

## Error Handling
- Centralized error message sanitization (never display raw error.message)
- Error boundaries for component-level failures
- Toast notifications for user-facing errors

## TypeScript
- Strict mode enabled
- No `any` in production code
- Explicit types on exports
- Zod for runtime validation at API boundaries

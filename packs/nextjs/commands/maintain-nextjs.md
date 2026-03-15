<!-- managed by claude-code-starter [pack:nextjs] -->
# /maintain — Next.js Extras

Additional post-session checks for Next.js projects (loaded alongside base maintain.md):

- **Route health check**: Find directories with dynamic `[param]` sub-routes but no `page.tsx` (missing redirect pattern):
  ```bash
  find {{FRONTEND_DIR}}/app -type d | while read dir; do
    if ls "$dir" 2>/dev/null | grep -qE '^\['; then
      if [ ! -f "$dir/page.tsx" ]; then
        echo "MISSING page.tsx: $dir"
      fi
    fi
  done
  ```

- **Type check**: Run `{{FRONTEND_TYPE_CHECK_CMD}}` to verify no type errors introduced

- **Build check**: Verify the frontend builds without errors

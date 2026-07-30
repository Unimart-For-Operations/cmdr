---
name: makefile-convention
description: "Shared Makefile style guide used across all idpbuilder org repos: color output, sectioned help, status indicators, and CI patterns."
---

# Makefile Convention

All repos in the idpbuilder org follow a consistent Makefile style.

## Required Elements

### 1. Default Goal

```makefile
.DEFAULT_GOAL := help
```

### 2. Color Constants

```makefile
CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
RESET  := \033[0m
BOLD   := \033[1m
```

### 3. Status Indicators

```makefile
PASS := \033[0;32m[pass]\033[0m
FAIL := \033[0;31m[fail]\033[0m
WARN := \033[0;33m[warn]\033[0m
```

### 4. Silenced Commands

Every recipe line starts with `@` to suppress echo:

```makefile
target:
	@echo "doing something"
	@command --flag
```

### 5. Hand-Crafted Help

Help is **not auto-parsed** from `##` comments. Instead, it's hand-crafted with `printf` statements organized into bold sections with box-drawing headers:

```makefile
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@printf "$(BOLD)<repo> — <tagline>$(RESET)\n"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@printf "$(BOLD)Section Name$(RESET)\n"
	@printf "  $(CYAN)target$(RESET)         Description of target\n"
	@printf "  $(CYAN)other-target$(RESET)   Description of other target\n"
```

### 6. CI Pattern

Sequential numbered checks with error counter:

```makefile
ci:
	@ERRORS=0; \
	printf "\n$(BOLD)[1/N] Check name$(RESET)\n"; \
	if command; then printf "  $(PASS) passed\n"; \
	else printf "  $(FAIL) failed\n"; ERRORS=$$((ERRORS + 1)); fi; \
	\
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	if [ $$ERRORS -eq 0 ]; then \
	  printf "$(GREEN)All checks passed$(RESET)\n"; \
	else \
	  printf "$(RED)$$ERRORS check(s) failed$(RESET)\n"; exit 1; \
	fi
```

### 7. Common Targets

Every repo should have these where applicable:

| Target | Purpose |
|--------|---------|
| `help` | Show available commands (default goal) |
| `hooks` | Install git pre-commit hooks |
| `sync-docs` | Sync docs to cdc handbook/vault |
| `ci` | Run all local checks |

### 8. ORG_DIR Detection

```makefile
ORG_DIR := $(shell dirname "$(CURDIR)")
```

### 9. sync-docs Target

Source repos should delegate to unimart when available:

```makefile
sync-docs:
	@if command -v unimart >/dev/null 2>&1; then \
	  unimart newsstand sync; \
	elif [ -x "$(ORG_DIR)/unimart-employee-handbooks/cdc/scripts/sync-docs.sh" ]; then \
	  bash "$(ORG_DIR)/unimart-employee-handbooks/cdc/scripts/sync-docs.sh"; \
	else \
	  printf "$(RED)Docs sync unavailable$(RESET)\n"; exit 1; \
	fi
```

## Style Rules

1. **No auto-generated help** — hand-craft the help output for readability
2. **Use box-drawing characters** (`━`) for section dividers
3. **Group targets by section** in help output with bold headers
4. **Consistent column alignment** in help output using spaces
5. **`.PHONY` declarations** for all non-file targets
6. **Quote paths** containing variables: `"$(CURDIR)"`

# Contributing to Microsoft Fabric Automation Toolkit

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🎯 How to Contribute

### Reporting Bugs
- Use the GitHub issue tracker
- Describe the bug with clear steps to reproduce
- Include your PowerShell version and Az module versions
- Provide error messages and logs (remove sensitive data)

### Suggesting Enhancements
- Open an issue describing the enhancement
- Explain why it would be useful
- Provide examples of how it would work

### Pull Requests

1. **Fork** the repository
2. **Create** a feature branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make** your changes following our coding standards
4. **Test** your changes thoroughly
5. **Commit** with descriptive messages
   ```bash
   git commit -m "Add: Description of your feature"
   ```
6. **Push** to your fork
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Submit** a pull request

## 📝 Coding Standards

### PowerShell Scripts

- Use **approved verbs** (Get, Set, New, Remove, etc.)
- Follow **PascalCase** for function names
- Include **comment-based help** with examples
- Add **parameter validation** where appropriate
- Use `[CmdletBinding()]` for advanced functions
- Set `$ErrorActionPreference = 'Stop'` for robust error handling
- Include try/catch blocks for API calls

**Example:**
```powershell
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER Name
    Parameter description
.EXAMPLE
    Example usage
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name
)
```

### Python Scripts (when added)
- Follow PEP 8 style guide
- Use type hints
- Include docstrings
- Add unit tests

### Documentation
- Keep README.md up to date
- Document all parameters and return values
- Provide real-world examples
- Update CHANGELOG.md

## 🧪 Testing

Before submitting:
- Test scripts in a non-production workspace
- Verify error handling works correctly
- Check that verbose and debug output is helpful
- Ensure backward compatibility

## 📋 Commit Message Guidelines

Use conventional commit format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

**Examples:**
```
feat: Add script to manage Fabric lakehouses
fix: Correct error handling in Get-FabricManagedPrivateEndpoints
docs: Update README with authentication examples
```

## 🔐 Security

- Never commit credentials or tokens
- Use parameters or environment variables for sensitive data
- Review code for potential security issues
- Report security vulnerabilities privately via email

## ✅ Checklist Before Submitting PR

- [ ] Code follows the project's style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (README, function help)
- [ ] No hardcoded credentials or workspace IDs
- [ ] Tested in a Fabric workspace
- [ ] CHANGELOG.md updated

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 💬 Questions?

Feel free to open an issue for any questions about contributing!

---

Thank you for contributing to the Microsoft Fabric Automation Toolkit! 🎉

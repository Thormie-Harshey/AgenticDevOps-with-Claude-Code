# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static HTML/CSS portfolio website deployed to AWS using S3 + CloudFront, provisioned with Terraform, and automated via GitHub Actions.

## Deployment

The site is hosted via Nginx on an Ubuntu VM. Deployment steps:

```bash
# Copy files to Nginx web root
sudo cp -r . /var/www/html/

# Restart Nginx
sudo systemctl restart nginx

# Verify the site is accessible
curl http://<public-ip>
```

Access the deployed site at `http://<public-ip>`.

## Architecture

### Application (Static Site)
- **index.html** — Single-page portfolio (About, Services, Courses, Books, Community, Contact)
- **style.css** — All styling (~1145 lines), mobile-first responsive (breakpoints: 900px, 768px, 600px)
- **privacy.html / terms.html** — Standalone pages with inline styles
- **images/** — Static assets (logo, profile, course thumbnails, hero background)
- Pure HTML5 + CSS3, no JavaScript, no build step

### Infrastructure (`terraform/`)
- AWS S3 bucket for static site hosting (private, OAC-based access)
- CloudFront distribution as CDN with S3 origin
- GitHub OIDC provider + IAM role for keyless CI/CD auth
- Terraform state stored in S3 backend with DynamoDB locking
- All resources tagged with `Project` and `Environment`

## Conventions
- No JavaScript allowed in the project
- Mobile-first CSS approach
- All images stored in images/

## DMI Ownership Customization (Required)

Before deployment, students must edit the footer in `index.html` (around line 604) to add ownership proof:

```html
<!-- Original line -->
<p>Crafted with <span>cloud</span> excellence by Pravin Mishra</p>

<!-- Add below it -->
<p><strong>Deployed by:</strong> DMI Cohort 2 | Your Name | Group # | Week 1 | DD-MM-YYYY</p>
```

This customized footer must be visible in a browser screenshot submitted as deployment proof.

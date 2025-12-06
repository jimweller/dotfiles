#!/usr/bin/env python3
"""
Export Confluence spaces and pages to local HTML files.
Preserves images, tables, and all formatting.
"""

import os
import sys
import yaml
import requests
import argparse
import urllib.parse
import re
from pathlib import Path
from urllib.parse import urljoin
from base64 import b64encode


def load_env_file(env_file):
    """Load environment variables from a file."""
    env_vars = {}
    if not os.path.exists(env_file):
        print(f"Error: Environment file not found: {env_file}")
        sys.exit(1)
    
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                # Remove 'export' keyword if present
                if line.startswith('export '):
                    line = line[7:]
                if '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip().strip('"').strip("'")
    return env_vars


def get_confluence_client(env_vars):
    """Create Confluence API client."""
    base_url = env_vars.get('CONFLUENCE_URL') or env_vars.get('ATLASSIAN_URL')
    username = env_vars.get('CONFLUENCE_USERNAME') or env_vars.get('ATLASSIAN_USERNAME')
    api_token = env_vars.get('CONFLUENCE_API_TOKEN') or env_vars.get('ATLASSIAN_API_TOKEN')
    
    if not all([base_url, username, api_token]):
        print("Error: Missing required environment variables:")
        print("  CONFLUENCE_URL (or ATLASSIAN_URL)")
        print("  CONFLUENCE_USERNAME (or ATLASSIAN_USERNAME)")
        print("  CONFLUENCE_API_TOKEN (or ATLASSIAN_API_TOKEN)")
        sys.exit(1)
    
    # Ensure base_url ends with /wiki
    if not base_url.endswith('/wiki'):
        base_url = base_url.rstrip('/') + '/wiki'
    
    return {
        'base_url': base_url,
        'auth': (username, api_token),
        'headers': {'Accept': 'application/json'}
    }


def get_space_pages(client, space_key):
    """Get all pages in a space."""
    api_url = f"{client['base_url']}/rest/api/content"
    pages = []
    start = 0
    limit = 100
    
    while True:
        params = {
            'spaceKey': space_key,
            'type': 'page',
            'status': 'current',
            'expand': 'version,space,body.export_view,ancestors',
            'start': start,
            'limit': limit
        }
        
        response = requests.get(api_url, auth=client['auth'], headers=client['headers'], params=params)
        
        if response.status_code != 200:
            print(f"Error fetching pages from space {space_key}: {response.status_code}")
            print(response.text)
            break
        
        data = response.json()
        pages.extend(data['results'])
        
        if len(data['results']) < limit:
            break
        
        start += limit
    
    return pages


def get_page_by_title(client, space_key, title):
    """Get a specific page by title in a space."""
    api_url = f"{client['base_url']}/rest/api/content"
    params = {
        'spaceKey': space_key,
        'title': title,
        'type': 'page',
        'expand': 'version,space,body.export_view,ancestors'
    }
    
    response = requests.get(api_url, auth=client['auth'], headers=client['headers'], params=params)
    
    if response.status_code != 200:
        print(f"Error fetching page '{title}' from space {space_key}: {response.status_code}")
        return None
    
    data = response.json()
    if data['results']:
        return data['results'][0]
    return None


def get_page_by_id(client, page_id):
    """Get a specific page by ID."""
    api_url = f"{client['base_url']}/rest/api/content/{page_id}"
    params = {
        'expand': 'version,space,body.export_view,ancestors'
    }
    
    response = requests.get(api_url, auth=client['auth'], headers=client['headers'], params=params)
    
    if response.status_code != 200:
        print(f"Error fetching page ID {page_id}: {response.status_code}")
        return None
    
    return response.json()


def get_child_pages(client, page_id):
    """Get all child pages of a page."""
    api_url = f"{client['base_url']}/rest/api/content/{page_id}/child/page"
    children = []
    start = 0
    limit = 100
    
    while True:
        params = {
            'start': start,
            'limit': limit,
            'expand': 'version,space,body.export_view,ancestors'
        }
        
        response = requests.get(api_url, auth=client['auth'], headers=client['headers'], params=params)
        
        if response.status_code != 200:
            break
        
        data = response.json()
        children.extend(data['results'])
        
        if len(data['results']) < limit:
            break
        
        start += limit
    
    return children


def get_all_descendant_pages(client, page_id):
    """Recursively get all descendant pages of a page."""
    descendants = []
    children = get_child_pages(client, page_id)
    
    for child in children:
        descendants.append(child)
        # Recursively get descendants of this child
        child_descendants = get_all_descendant_pages(client, child['id'])
        descendants.extend(child_descendants)
    
    return descendants


def download_attachment(client, attachment_url, dest_path):
    """Download an attachment from Confluence."""
    if not attachment_url.startswith('http'):
        attachment_url = urljoin(client['base_url'], attachment_url)
    
    try:
        # Use same headers as API calls
        headers = {
            'Accept': 'application/octet-stream',
            'X-Atlassian-Token': 'no-check'
        }
        response = requests.get(attachment_url, auth=client['auth'], headers=headers, stream=True, timeout=30)
        
        if response.status_code == 200:
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with open(dest_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return True
        else:
            # Try without /wiki/ prefix if present
            if '/wiki/download/' in attachment_url:
                alt_url = attachment_url.replace('/wiki/download/', '/download/')
                response = requests.get(alt_url, auth=client['auth'], headers=headers, stream=True, timeout=30)
                if response.status_code == 200:
                    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                    with open(dest_path, 'wb') as f:
                        for chunk in response.iter_content(chunk_size=8192):
                            f.write(chunk)
                    return True
            print(f"      HTTP {response.status_code}: {attachment_url}")
            return False
    except Exception as e:
        print(f"      Error downloading: {str(e)}")
        return False


def get_page_attachments(client, page_id):
    """Get all attachments for a page using API v2."""
    # Use API v2 which has downloadLink field
    api_url = f"{client['base_url']}/api/v2/pages/{page_id}/attachments"
    attachments = []
    cursor = None
    limit = 100
    
    while True:
        params = {
            'limit': limit
        }
        if cursor:
            params['cursor'] = cursor
        
        response = requests.get(api_url, auth=client['auth'], headers=client['headers'], params=params)
        
        if response.status_code != 200:
            print(f"      Attachment API error: HTTP {response.status_code}")
            break
        
        data = response.json()
        results = data.get('results', [])
        
        # Convert v2 format to v1-like format for compatibility
        for att in results:
            # API v2 provides downloadLink directly
            attachments.append({
                'title': att.get('title', ''),
                'id': att.get('id', ''),
                'downloadLink': att.get('downloadLink', ''),
                '_links': {
                    'download': att.get('downloadLink', '')
                }
            })
        
        if not results or len(results) < limit:
            break
        
        # API v2 uses cursor-based pagination
        next_link = data.get('_links', {}).get('next')
        if not next_link:
            break
        
        # Extract cursor from next link if available
        if 'cursor=' in next_link:
            cursor = next_link.split('cursor=')[1].split('&')[0]
        else:
            break
    
    return attachments


def sanitize_filename(name):
    """Sanitize a string to be used as a filename."""
    invalid_chars = '<>:"/\\|?*'
    for char in invalid_chars:
        name = name.replace(char, '_')
    return name.strip()


def export_page(client, page, dest_dir, space_key):
    """Export a single page with its attachments and embedded images."""
    page_title = page['title']
    page_id = page['id']
    
    print(f"  Exporting page: {page_title}")
    
    # Build path based on parent hierarchy
    path_parts = [space_key]
    
    # Get ancestors (parent pages) and build path
    ancestors = page.get('ancestors', [])
    for ancestor in ancestors:
        ancestor_title = sanitize_filename(ancestor['title'])
        path_parts.append(ancestor_title)
    
    # Add current page
    safe_title = sanitize_filename(page_title)
    path_parts.append(safe_title)
    
    # Create directory for this page
    page_dir = os.path.join(dest_dir, *path_parts)
    os.makedirs(page_dir, exist_ok=True)
    
    # Get page content (export_view format has rendered HTML)
    html_content = page['body']['export_view']['value']
    
    # Create attachments directory
    attachments_dir = os.path.join(page_dir, 'attachments')
    os.makedirs(attachments_dir, exist_ok=True)
    
    # Download all attachments from API and track downloaded filenames
    attachments = get_page_attachments(client, page_id)
    downloaded_files = set()
    
    for attachment in attachments:
        att_title = attachment['title']
        # Construct clean download URL without version parameters
        # The API returns URLs with stale version params that cause 404s
        download_link = f"{client['base_url']}/download/attachments/{page_id}/{att_title}"
        att_path = os.path.join(attachments_dir, att_title)
        
        if download_attachment(client, download_link, att_path):
            downloaded_files.add(att_title)
            
            # Replace ALL variations of attachment URLs in HTML with local reference
            # The export_view HTML contains different URL formats:
            # 1. /wikiattachments/{filename}
            # 2. /download/attachments/{page_id}/{filename}?params
            # 3. https://domain.atlassian.net/wikiattachments/{filename}
            # 4. https://domain.atlassian.net/download/attachments/{page_id}/{filename}?params
            
            # Pattern 1: Match wikiattachments URLs (used in export_view HTML)
            wiki_pattern = re.compile(
                rf'(?:https?://[^/]+)?/wikiattachments/{re.escape(att_title)}',
                re.IGNORECASE
            )
            html_content = wiki_pattern.sub(f'attachments/{att_title}', html_content)
            
            # Pattern 2: Match download/attachments URLs (with optional /wiki/ prefix)
            download_pattern = re.compile(
                rf'(?:https?://[^/]+)?(?:/wiki)?/download/attachments/{page_id}/{re.escape(att_title)}(\?[^"\'\s]*)?',
                re.IGNORECASE
            )
            html_content = download_pattern.sub(f'attachments/{att_title}', html_content)
    
    # Report attachment download count
    if len(downloaded_files) > 0:
        print(f"    Downloaded {len(downloaded_files)} attachment(s)")
    
    # Remove Confluence UI elements (spinners, icons) that don't exist locally
    # These are just UI decorations, not content
    ui_pattern = re.compile(r'<img[^>]*src="/wiki/s/[^"]*"[^>]*>', re.IGNORECASE)
    html_content = ui_pattern.sub('', html_content)
    
    # Create HTML file with metadata
    html_file = os.path.join(page_dir, 'index.html')
    full_html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>{page_title}</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }}
        .metadata {{ background: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
        .metadata p {{ margin: 5px 0; }}
        table {{ border-collapse: collapse; width: 100%; margin: 10px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        th {{ background-color: #f2f2f2; }}
        img {{ max-width: 100%; height: auto; }}
    </style>
</head>
<body>
    <div class="metadata">
        <p><strong>Space:</strong> {space_key}</p>
        <p><strong>Page ID:</strong> {page_id}</p>
        <p><strong>Version:</strong> {page['version']['number']}</p>
        <p><strong>Last Modified:</strong> {page['version']['when']}</p>
        <p><strong>Modified By:</strong> {page['version']['by']['displayName']}</p>
    </div>
    <h1>{page_title}</h1>
    {html_content}
</body>
</html>
"""
    
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(full_html)


def export_space(client, space_key, page_titles, dest_dir):
    """Export a space or specific pages from a space."""
    print(f"\nExporting space: {space_key}")
    
    if not page_titles:
        # Export entire space
        pages = get_space_pages(client, space_key)
        print(f"Found {len(pages)} pages in space {space_key}")
        for page in pages:
            export_page(client, page, dest_dir, space_key)
    else:
        # Export specific pages and all their descendants
        print(f"Exporting {len(page_titles)} specific pages (including child pages)")
        for title in page_titles:
            page = get_page_by_title(client, space_key, title)
            if page:
                # Export the parent page
                export_page(client, page, dest_dir, space_key)
                
                # Export all descendant pages recursively
                descendants = get_all_descendant_pages(client, page['id'])
                if descendants:
                    print(f"    Found {len(descendants)} child pages under '{title}'")
                    for descendant in descendants:
                        export_page(client, descendant, dest_dir, space_key)
            else:
                print(f"  Warning: Page '{title}' not found in space {space_key}")


def load_config(config_file):
    """Load configuration from YAML file."""
    if not os.path.exists(config_file):
        print(f"Error: Config file not found: {config_file}")
        sys.exit(1)
    
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    return config


def main():
    parser = argparse.ArgumentParser(
        description='Export Confluence spaces and pages to HTML',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s /path/to/export
  %(prog)s -c custom-config.yaml /path/to/export
  
Configuration file format (YAML):
  spaces:
    - SPACEKEY1
    - SPACEKEY2:
      - "Page Title 1"
      - "Page Title 2"
        """
    )
    
    parser.add_argument('dest_folder', help='Destination folder for exports')
    parser.add_argument('-c', '--config', default=os.path.expanduser('~/.secrets/confluence-export.yaml'),
                       help='Path to config file (default: ~/.secrets/confluence-export.yaml)')
    parser.add_argument('-e', '--env-file', default=os.path.expanduser('~/.secrets/atlassian.env'),
                       help='Path to environment file (default: ~/.secrets/atlassian.env)')
    
    args = parser.parse_args()
    
    # Load environment variables
    env_vars = load_env_file(args.env_file)
    
    # Create Confluence client
    client = get_confluence_client(env_vars)
    
    # Load configuration
    config = load_config(args.config)
    
    # Create destination directory
    dest_dir = os.path.abspath(args.dest_folder)
    os.makedirs(dest_dir, exist_ok=True)
    
    print(f"Exporting to: {dest_dir}")
    print(f"Using config: {args.config}")
    
    # Process each space
    spaces = config.get('spaces', [])
    if not spaces:
        print("Error: No spaces defined in configuration file")
        sys.exit(1)
    
    for item in spaces:
        if isinstance(item, str):
            # Simple space key - export entire space
            export_space(client, item, None, dest_dir)
        elif isinstance(item, dict):
            # Space with specific pages
            for space_key, pages in item.items():
                export_space(client, space_key, pages, dest_dir)
    
    print("\nExport complete!")


if __name__ == '__main__':
    main()
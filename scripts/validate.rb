#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "uri"

ERRORS = []

def check(condition, message)
  ERRORS << message unless condition
end

config = YAML.safe_load(File.read(".upptimerc.yml"), aliases: false)
check(config.is_a?(Hash), ".upptimerc.yml must be a mapping")
check(config["owner"] == "TryMightyAI", "owner must be TryMightyAI")
check(config["repo"] == "status", "repo must be status")
check(config["secrets"] == [], "monitor secret allowlist must remain explicit and empty")
check(config["skipDeleteIssues"] == true, "short incidents must be retained")
%w[skipDescriptionUpdate skipTopicsUpdate skipHomepageUpdate].each do |key|
  check(config[key] == true, "#{key}: automation must not rewrite repository metadata")
end
check(config.dig("status-website", "cname") == "status.trymighty.ai", "custom domain changed")
check(config.dig("status-website", "logoUrl") == "/mighty-logo.png", "logo must be served with the static page")
check(config.dig("status-website", "favicon") == "/favicon.png", "favicon must use the square asset")
check(config.dig("status-website", "themeUrl") == "/mighty-theme.css", "custom Mighty theme must remain enabled")
check(config.dig("status-website", "name") == "Mighty Service Status", "status page needs a descriptive title")
check(config.dig("status-website", "introMessage").to_s.include?("Mighty detects manipulated documents and media"),
      "status page must explain Mighty's product in plain language")
check(config.dig("status-website", "links").to_a.any? { |link| link == { "rel" => "canonical", "href" => "https://status.trymighty.ai/" } },
      "status page must publish its canonical URL")
meta_tags = config.dig("status-website", "metaTags").to_a
check(meta_tags.any? { |tag| tag["name"] == "description" && tag["content"].to_s.include?("AI document-fraud detection") },
      "status page must publish an accurate search description")
check(config.dig("status-website", "customHeadHtml").to_s.include?("application/ld+json"),
      "status page must publish structured data")
check(config.dig("status-website", "robotsText").to_s.include?("https://status.trymighty.ai/sitemap.xml"),
      "robots.txt must advertise the sitemap")
%w[mighty-theme.css status-social-card.png sitemap.xml llms.txt manifest.json logo-192.png logo-512.png].each do |asset|
  path = File.join("assets", asset)
  check(File.file?(path) && File.size(path).positive?, "missing status presentation/discovery asset #{asset}")
end

theme_css = File.read("assets/mighty-theme.css")
check(theme_css.include?("outline: 3px solid #127294"),
      "interactive elements must retain a high-contrast keyboard focus indicator")

sites = config.fetch("sites", [])
check(sites.length >= 3, "at least three customer-facing components are required")
slugs = sites.map { |site| site["slug"] }
check(slugs.compact.length == sites.length, "every component needs an explicit slug")
check(slugs.uniq.length == slugs.length, "component slugs must be unique")

expected_bodies = {
  "api" => '"status":"healthy"',
  "scan-gateway" => '"status":"ok"'
}

sites.each do |site|
  check(site["method"] == "GET", "#{site["name"]}: checks must use GET")
  if expected_bodies.key?(site["slug"])
    check(site["__dangerous__body_down_if_text_missing"] == expected_bodies[site["slug"]],
          "#{site["name"]}: health-body assertion changed")
  end
  begin
    uri = URI.parse(site.fetch("url"))
    check(uri.is_a?(URI::HTTPS), "#{site["name"]}: URL must use HTTPS")
    check(uri.userinfo.nil?, "#{site["name"]}: URL must not contain credentials")
    check(uri.query.nil?, "#{site["name"]}: public checks must not put secrets/query data in URLs")
  rescue StandardError => e
    ERRORS << "#{site["name"] || "unnamed site"}: invalid URL (#{e.message})"
  end
  check(site["expectedStatusCodes"] == [200], "#{site["name"]}: require an exact HTTP 200")
  check(site["maxResponseTime"].is_a?(Integer) && site["maxResponseTime"] <= 10_000,
        "#{site["name"]}: maxResponseTime must be an integer no greater than 10 seconds")
end

workflow_dir = ".github/workflows"
forbidden = %w[setup.yml update-template.yml updates.yml]
forbidden.each do |name|
  check(!File.exist?(File.join(workflow_dir, name)), "self-modifying workflow #{name} must stay removed")
end

runtime_workflows = %w[uptime.yml response-time.yml site.yml]
runtime_workflows.each do |name|
  path = File.join(workflow_dir, name)
  check(File.exist?(path), "missing runtime workflow #{name}")
  next unless File.exist?(path)

  content = File.read(path)
  begin
    YAML.safe_load(content, aliases: false)
  rescue StandardError => e
    ERRORS << "#{name}: invalid YAML (#{e.message})"
  end
  check(content.include?("permissions:
  contents: read"), "#{name}: top-level token must be read-only")
  check(content.include?("timeout-minutes:"), "#{name}: job needs a timeout")
  check(content.include?("if: github.ref == 'refs/heads/main' && vars.STATUS_AUTOMATION_ENABLED == 'true'"),
        "#{name}: production automation needs the explicit launch gate")
  check(!content.include?("pull_request_target"), "#{name}: pull_request_target is forbidden")
  check(!content.include?("repository_dispatch"), "#{name}: repository_dispatch is not required")
  check(!content.include?("GH_PAT"), "#{name}: long-lived PATs are forbidden")
  check(!content.include?("secrets."), "#{name}: production jobs must not consume repository secrets")

  content.scan(/^\s*uses:\s*([^\s#]+)/).flatten.each do |action|
    next if action.start_with?("./")
    check(action.match?(/\A[^@]+@[0-9a-f]{40}\z/), "#{name}: action is not full-SHA pinned: #{action}")
  end
end

site_content = File.read(File.join(workflow_dir, "site.yml"))
check(site_content.include?("ref: 54c2ff5a3d998d525ee4c7e68dc7ce7414d89c33 # v1.17.0"),
      "static site source must stay pinned to Upptime status-page v1.17.0")
check(site_content.include?("npm ci --no-audit --no-fund"),
      "static site must use its upstream package lock")
check(!site_content.include?("command: site"),
      "do not use Upptime's floating npm status-page install")
status_page_patch = File.read("patches/upptime-status-page-main.patch")
check(status_page_patch.scan("/master/").length == 4,
      "main-branch compatibility patch changed unexpectedly")
check(status_page_patch.include?("<title>{serviceName} status history | Mighty</title>"),
      "component history pages must publish descriptive titles")
check(status_page_patch.include?(".r input:focus-visible + label") &&
      !status_page_patch.include?("+    display: none;"),
      "time-range radio controls must remain keyboard accessible")
check(status_page_patch.include?('--entry "/ /history/website /history/api /history/scan-gateway"'),
      "static export must emit direct HTTP-200 component history routes")

%w[uptime.yml response-time.yml].each do |name|
  content = File.read(File.join(workflow_dir, name))
  check(content.include?("group: ${{ github.repository }}-upptime-main-writer"),
        "#{name}: main writers must share one concurrency group")
  check(content.include?("      contents: write
      issues: write"),
        "#{name}: ephemeral token needs only Contents/Issues write")
  check(content.include?("GITHUB_TOKEN: ${{ github.token }}"),
        "#{name}: monitor must use the ephemeral job token")
end
check(site_content.include?("      contents: write"),
      "site.yml: publisher needs job-scoped Contents write")
check(site_content.include?("github_token: ${{ github.token }}"),
      "site.yml: publisher must use the ephemeral job token")

check(!File.read("README.md").include?("<!--start: status pages-->"),
      "README summary markers would generate links to intentionally omitted PNG graphs")

validate_path = File.join(workflow_dir, "validate.yml")
if File.exist?(validate_path)
  validate_content = File.read(validate_path)
  validate_content.scan(/^\s*uses:\s*([^\s#]+)/).flatten.each do |action|
    next if action.start_with?("./")
    check(action.match?(/\A[^@]+@[0-9a-f]{40}\z/), "validate.yml: action is not full-SHA pinned: #{action}")
  end
end

headers = File.read("assets/_headers")
check(headers.include?("Content-Security-Policy: default-src 'self'"), "Cloudflare headers must set a CSP")
check(headers.include?("X-Content-Type-Options: nosniff"), "Cloudflare headers must disable MIME sniffing")
check(headers.include?("X-Frame-Options: DENY"), "Cloudflare headers must prevent framing")
check(headers.include?("Strict-Transport-Security:"), "Cloudflare headers must enable HSTS")

issue_template = File.read(".github/ISSUE_TEMPLATE/scheduled-maintenance.md")
first_metadata = issue_template.split("<!--", 2)[1]&.split("-->", 2)&.first.to_s
check(first_metadata.include?("start: 2000-01-01T00:00:00Z"),
      "first maintenance comment needs a safe start placeholder")
check(first_metadata.include?("end: 2000-01-01T00:30:00Z"),
      "first maintenance comment needs a safe end placeholder")
check(first_metadata.include?("expectedDown:") && first_metadata.include?("expectedDegraded:"),
      "first maintenance comment needs optional impact metadata")

if ERRORS.empty?
  puts "Status configuration validation passed (#{sites.length} components, full-SHA workflows)."
else
  warn "Status configuration validation failed:"
  ERRORS.each { |error| warn "- #{error}" }
  exit 1
end

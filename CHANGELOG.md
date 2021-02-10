# Changelog

## Back In Stock - v0.3 (2021-02-10)
- Add ability to associate another product to back in stock notifications to support kit pages
  This enables the kit name to be included in emails together with the component name that is back in stock
- Bug fix to include all pending records in CSV download - not just the first page
- Improve CSV download performance by preloading product, variant and stocklocation data

## Back In Stock - v0.2 (2021-02-03)
- Add admin summary page and link to admin nav bar

## Back In Stock - v0.1 (2021-01-15)

First release. Features:
- ability to sign up to back in stock notification
- admin page to view pending back in stock notifications
- job and mailer for sending back in stock notifications (to be triggered by a rake task)

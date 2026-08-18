# Health data collector, importer and viewer

Upload weight and body fat data from your Fitbit Aria scale into your own MySQL database and view the data without sending the data to a third party.

You may want to use this to keep your health data private. Personally I use it because when Google bought Fitbit the removed the ability to view your data without using a mobile phone app. I want the ability to view my data on the web.

There are three components to this project:

- `apps/fitbit-collector/` — Receives Fitbit Aria uploads and writes them to the database.
- `jobs/health-data-etl/` — Imports your historical weight and body fat data from Google Takeout.
- `apps/health-dashboard/` — Shows your weight and body fat graphs in a web interface.

## Dependencies

This project will run in a standard LAMP, WAMP, or MAMP (Linux/Windows/Mac, Perl, Apache, MySQL) environment.

- Perl (version 5.14+)
- Apache (version 2.4+)
- MySQL (version 8.0+)

Fitbit Aria scales are hard-coded to send data to `www.fitbit.com`. To make the scale connect to your local server, you will need the ability to override DNS locally to provide a different IP address for Fitbit's hostname.

## Installation

1. Create a MySQL database and user:
   ```sql
   CREATE DATABASE health_data;
   CREATE USER 'health_user'@'localhost' IDENTIFIED BY 'your_secure_password';
   GRANT ALL PRIVILEGES ON health_data.* TO 'health_user'@'localhost';
   FLUSH PRIVILEGES;
   ```
   Adjust the database name, username, and password as needed.
1. Create a `.env` file in the project root
   ```ini
   MYSQL_USER=health_user
   MYSQL_DATABASE=health_data
   MYSQL_PWD=your_secure_password
   MYSQL_HOST=localhost
   MYSQL_PORT=3306
   HEALTH_DASHBOARD_HOST=health.localdomain
   ```
1. Run `make schema` to initialize the MySQL schema and run migrations.
1. Run `make etl-load` to load any existing CSV exports.
1. Set up `apps/fitbit-collector/` to ingest Fitbit Aria device uploads directly into the database.
1. Configure `apps/health-dashboard/` to read from the same MySQL database and visualize metrics.

## Common Commands

From the repository root:

```sh
make schema      # Initialize database and run migrations
make test
make install
make etl-normalize
make etl-load
make etl-refresh
```

Project-specific details:
- [apps/fitbit-collector/readme.md](apps/fitbit-collector/readme.md)
- [jobs/health-data-etl/readme.md](jobs/health-data-etl/readme.md)
- [apps/health-dashboard/readme.md](apps/health-dashboard/readme.md)

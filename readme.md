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

1. Make sure MySQL is running `sudo service mysql start`
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
1. (Optional) Import historical weight and body fat data from a Google Takeout export:
   ```sh
   jobs/health-data-etl/script/etl.pl /path/to/takeout-export.tgz
   ```
   See [jobs/health-data-etl/readme.md](jobs/health-data-etl/readme.md) for detailed instructions.
1. Run `make install` to install the virtual host configs for the fitbit collector and the health dashboard into `/etc/apache2/`
1. Restart or reload apache: `sudo service apache2 restart`
1. Configure your local DNS server to override the IP address for `www.fitbit.com`
1. Test that your scale uploads data.
1. Log into the health dashboard. The password you use when you first log in will create the password in the database. If you imported data from Google Takeout you can use your email address from the import as the user name. Otherwise you will need to use your Fitbit user id. Your scale sends it when it uploads data and you can find it in the `metric_fact` table in the database.
1. Once you have logged in, you can use the "edit user" functionality in the hamburger menu to set your user name.


## Common Commands

From the repository root:

```sh
make schema      # Initialize database and run migrations
make test        # Run all test suites
make install     # Install application dependencies
jobs/health-data-etl/script/etl.pl /path/to/takeout-export.tgz  # Import historical data from Takeout
```

Project-specific details:
- [apps/fitbit-collector/readme.md](apps/fitbit-collector/readme.md)
- [jobs/health-data-etl/readme.md](jobs/health-data-etl/readme.md)
- [apps/health-dashboard/readme.md](apps/health-dashboard/readme.md)

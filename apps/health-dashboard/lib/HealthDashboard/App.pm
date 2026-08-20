package HealthDashboard::App;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP;
use HTML::Entities qw(encode_entities);
use Digest::SHA qw(sha1_hex);

use HealthDashboard::Metrics qw(default_metric metrics_for_client metric_definition);
use HealthDashboard::Queries qw(fetch_series_data validate_range supported_granularities);
use HealthDashboard::Auth qw(get_user_id_from_cookie authenticate_user create_auth_cookie set_user_password get_user_by_id_or_name user_exists);
use HealthDashboard::DB qw(load_env_file);

our @EXPORT_OK = qw(render_dashboard_page render_series_response);

sub render_dashboard_page {
	my (%args) = @_;
	my $cookie = $args{cookie};
	my $nonce = _generate_nonce();

	my $user_id = get_user_id_from_cookie(cookie => $cookie);

	if (!defined $user_id || $user_id eq '') {
		my $body = _render_login_page(nonce => $nonce);
		return _wrap_response(body => $body, nonce => $nonce);
	}

	my $body = _render_authenticated_dashboard($user_id, nonce => $nonce);
	return _wrap_response(body => $body, nonce => $nonce);
}

sub _generate_nonce {
	return sha1_hex(rand() . time() . $$);
}

sub _build_security_headers {
	my ($nonce) = @_;
	return [
		'X-Content-Type-Options', 'nosniff',
		'X-Frame-Options', 'DENY',
		'Referrer-Policy', 'strict-origin-when-cross-origin',
		'Content-Security-Policy', "default-src 'self'; script-src 'self' 'nonce-$nonce'; style-src 'self' 'unsafe-inline'",
	];
}

sub _wrap_response {
	my (%args) = @_;
	my $body = $args{body};
	my $nonce = $args{nonce} || _generate_nonce();
	my $headers = _build_security_headers($nonce);

	return {
		status => 200,
		headers => $headers,
		body => $body,
	};
}

sub _render_authenticated_dashboard {
	my ($user_id, %args) = @_;
	my $nonce = $args{nonce} || '';

	my $user = get_user_by_id_or_name(login => $user_id);
	my $user_name = $user ? $user->{name} : 'User';
	my $escaped_user_name = encode_entities($user_name);
	my $user_height = $user ? ($user->{height_mm} || '') : '';
	my $user_gender = _normalize_gender($user ? ($user->{gender} || 'unknown') : 'unknown');
	my $user_unit_preference = $user ? ($user->{unit_preference} || 'imperial') : 'imperial';
	my $user_username = $user ? ($user->{user_name} || '') : '';
	my $user_initials = $user ? ($user->{initials} || '') : '';
	my $user_birthdate = $user ? ($user->{birthdate} || '') : '';

	my $config = JSON::PP->new->ascii->canonical->encode({
		defaultMetric => default_metric(),
		metrics => metrics_for_client(),
		granularities => [supported_granularities()],
		userId => $user_id,
		userName => $user_name,
		userHeight => $user_height,
		userGender => $user_gender,
		userUnitPreference => $user_unit_preference,
		userUsername => $user_username,
		userInitials => $user_initials,
		userBirthdate => $user_birthdate,
	});
	$config =~ s{</}{<\\/}g;

	return <<"HTML";
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Health Dashboard</title>
  <link rel="icon" type="image/svg+xml" href="static/health.svg">
  <link rel="stylesheet" href="static/dashboard.css">
</head>
<body>
  <div class="page">
    <section class="hero">
      <div>
        <h1><img src="static/health.svg" alt="Health" style="height:1.2em;vertical-align:middle;margin-right:0.3em">Health dashboard</h1>
        <p>Welcome, $escaped_user_name</p>
      </div>
      <div class="menu-container">
        <button id="menu-toggle" class="menu-toggle" aria-label="Menu">
          <span></span>
          <span></span>
          <span></span>
        </button>
        <div id="menu" class="menu">
          <button id="menu-edit-user" class="menu-item">Edit User</button>
          <button id="menu-logout" class="menu-item menu-logout">Logout</button>
        </div>
      </div>
    </section>

    <div id="edit-user-modal" class="modal">
      <div class="modal-content">
        <span class="close">&times;</span>
        <h2>Edit User</h2>
        <form id="edit-user-form">
          <div class="form-group">
            <label for="user-name">Name:</label>
            <input type="text" id="user-name" name="user-name" required maxlength="20">
          </div>

          <div class="form-group">
            <label for="user-username">User Name:</label>
            <input type="text" id="user-username" name="user-username" maxlength="30">
          </div>

          <div class="form-group">
            <label for="user-initials">Initials:</label>
            <input type="text" id="user-initials" name="user-initials" maxlength="3">
          </div>

          <div class="form-group">
            <label for="user-gender">Gender:</label>
            <select id="user-gender" name="user-gender">
              <option value="unknown">Unknown</option>
              <option value="male">Male</option>
              <option value="female">Female</option>
            </select>
          </div>

          <div class="form-group">
            <label for="user-birthdate">Birthdate:</label>
            <input type="date" id="user-birthdate" name="user-birthdate">
          </div>

          <div class="form-group">
            <label for="unit-preference">Unit Preference:</label>
            <select id="unit-preference" name="unit-preference">
              <option value="imperial">Imperial (feet, inches)</option>
              <option value="metric">Metric (meters)</option>
            </select>
          </div>

          <div class="form-group">
            <label>Height:</label>
            <div id="imperial-inputs" class="height-inputs">
              <div class="height-input-group">
                <label for="height-feet">Feet:</label>
                <input type="number" id="height-feet" name="height-feet" min="0" max="9">
              </div>
              <div class="height-input-group">
                <label for="height-inches">Inches:</label>
                <input type="number" id="height-inches" name="height-inches" min="0" max="11" step="0.5">
              </div>
            </div>
            <div id="metric-inputs" class="height-inputs" style="display: none;">
              <div class="height-input-group">
                <label for="height-meters">Height (m):</label>
                <input type="number" id="height-meters" name="height-meters" min="0" step="0.01">
              </div>
            </div>
          </div>

          <button type="submit">Save</button>
        </form>
      </div>
    </div>

    <form id="controls" class="controls">
      <div class="control">
        <label for="metric">Metric</label>
        <select id="metric" name="metric"></select>
      </div>
      <div class="control">
        <label for="granularity">Granularity</label>
        <select id="granularity" name="granularity">
          <option value="auto" selected>Auto</option>
          <option value="day">Day</option>
          <option value="week">Week</option>
          <option value="month">Month</option>
          <option value="year">Year</option>
        </select>
      </div>
      <div class="control">
        <label for="aggregation">Aggregation</label>
        <select id="aggregation" name="aggregation">
          <option value="range" selected>Range (Min/Avg/Max)</option>
          <option value="mean">Average</option>
          <option value="min">Minimum</option>
          <option value="max">Maximum</option>
        </select>
      </div>
      <div class="control">
        <label for="time-period">Time period</label>
        <select id="time-period" name="time-period"></select>
      </div>
      <div class="control date-control" style="display: none;">
        <label for="start">Start</label>
        <input id="start" name="start" type="date">
      </div>
      <div class="control date-control" style="display: none;">
        <label for="end">End</label>
        <input id="end" name="end" type="date">
      </div>
    </form>

    <div id="range-error" class="range-error" role="alert"></div>

    <section class="chart-panel">
      <div style="height: 420px;">
        <canvas id="health-chart"></canvas>
      </div>
      <div id="chart-status"></div>
    </section>

    <section class="summary-panel">
      <div id="summary" class="summary-grid"></div>
    </section>
  </div>

  <script nonce="$nonce">window.dashboardConfig = $config;</script>
  <script src="static/vendor/chart.umd.js"></script>
  <script src="static/dashboard.js"></script>
</body>
</html>
HTML
}

sub render_series_response {
	my (%args) = @_;
	my $params = _parse_query_string($args{query_string} // '');
	my $user_id = $args{user_id};
	my $metric = $params->{metric} || default_metric();
	my $granularity = $params->{granularity};
	my $aggregation = $params->{aggregation} || 'range';
	my $definition = metric_definition($metric);

	if (!$definition) {
		return _json_response(400, { error => 'Unknown metric' });
	}

	if (defined $granularity && $granularity ne 'auto') {
		my %valid_granularity = map { $_ => 1 } supported_granularities();
		if (!$valid_granularity{$granularity}) {
			return _json_response(400, { error => 'Unsupported granularity' });
		}
	} else {
		$granularity = undef;
	}

	my %valid_aggregation = map { $_ => 1 } qw(range mean min max);
	if (!$valid_aggregation{$aggregation}) {
		return _json_response(400, { error => 'Unsupported aggregation' });
	}

	my $range_error = validate_range(
		granularity => $granularity,
		start => $params->{start},
		end => $params->{end},
	);
	if ($range_error) {
		return _json_response(400, { error => $range_error });
	}

	my $result;
	eval {
		$result = fetch_series_data(
			metric => $metric,
			granularity => $granularity,
			aggregation => $aggregation,
			start => $params->{start},
			end => $params->{end},
			definition => $definition,
			user_id => $user_id,
		);
		1;
	} or do {
		my $error = $@ || 'Unknown query error';
		$error =~ s/\s+\z//;
		return _json_response(500, { error => $error });
	};

	return _json_response(200, $result);
}

sub _render_login_page {
	my (%args) = @_;
	my $nonce = $args{nonce} || '';

	load_env_file();
	my $is_demo_mode = $ENV{HEALTH_DASHBOARD_DEMO} ? 1 : 0;
	my $demo_login_value = $is_demo_mode ? 'value="demo"' : '';
	my $demo_password_value = $is_demo_mode ? 'value="demo"' : '';

	return <<"HTML";
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Health Dashboard Login</title>
  <link rel="icon" type="image/svg+xml" href="static/health.svg">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .login-box {
      background: white;
      padding: 40px;
      border-radius: 8px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
      width: 100%;
      max-width: 400px;
    }
    h1 {
      text-align: center;
      color: #333;
      margin-top: 0;
    }
    .form-group {
      margin-bottom: 20px;
    }
    label {
      display: block;
      margin-bottom: 5px;
      color: #555;
      font-weight: 500;
    }
    input {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 16px;
      box-sizing: border-box;
    }
    input:focus {
      outline: none;
      border-color: #667eea;
      box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }
    button {
      width: 100%;
      padding: 12px;
      background: #667eea;
      color: white;
      border: none;
      border-radius: 4px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 10px;
    }
    button:hover {
      background: #5568d3;
    }
    .error {
      color: #e74c3c;
      margin-bottom: 15px;
      padding: 10px;
      background: #fadbd8;
      border-radius: 4px;
      display: none;
    }
    .message {
      color: #27ae60;
      margin-bottom: 15px;
      padding: 10px;
      background: #d5f4e6;
      border-radius: 4px;
      display: none;
    }
  </style>
</head>
<body>
  <div class="login-box">
    <h1><img src="static/health.svg" alt="Health" style="height:1.2em;vertical-align:middle;margin-right:0.3em">Health Dashboard</h1>
    <div class="error" id="error"></div>
    <div class="message" id="message"></div>

    <form id="login-form">
      <div class="form-group">
        <label for="login">Name or User ID</label>
        <input type="text" id="login" name="login" required autofocus $demo_login_value>
      </div>
      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" required $demo_password_value>
      </div>
      <button type="submit">Login</button>
    </form>
  </div>

  <script nonce="$nonce">
    document.getElementById('login-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const login = document.getElementById('login').value;
      const password = document.getElementById('password').value;

      try {
        const response = await fetch('api/auth.cgi', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ action: 'login', login, password })
        });

        const data = await response.json();
        if (data.success) {
          window.location.reload();
        } else if (data.needsPassword) {
          const newPassword = prompt('Set a password for this account:');
          if (newPassword) {
            const setResponse = await fetch('api/auth.cgi', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ action: 'set_password', login, password: newPassword })
            });
            const setData = await setResponse.json();
            if (setData.success) {
              document.getElementById('message').textContent = 'Password set! Please login.';
              document.getElementById('message').style.display = 'block';
            }
          }
        } else {
          document.getElementById('error').textContent = data.error || 'Login failed';
          document.getElementById('error').style.display = 'block';
        }
      } catch (err) {
        document.getElementById('error').textContent = 'Error: ' + err.message;
        document.getElementById('error').style.display = 'block';
      }
    });
  </script>
</body>
</html>
HTML
}

sub _json_response {
	my ($status, $payload) = @_;
	my $body = JSON::PP->new->ascii->canonical->encode($payload);
	return {
		status => $status,
		headers => [
			'Content-Type', 'application/json; charset=utf-8',
			'Content-Length', length($body),
		],
		body => $body,
	};
}

sub _parse_query_string {
	my ($query_string) = @_;
	my %params;
	for my $pair (split /&/, $query_string) {
		next if $pair eq '';
		my ($key, $value) = split /=/, $pair, 2;
		$key = _percent_decode($key // '');
		$value = _percent_decode($value // '');
		$params{$key} = $value;
	}
	return \%params;
}

sub _percent_decode {
	my ($value) = @_;
	$value =~ tr/+/ /;
	$value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	return $value;
}

sub _normalize_gender {
	my ($value) = @_;
	return 'unknown' unless defined $value && length($value);

	my $lower = lc($value);
	return 'male' if $lower eq 'm' || $lower eq 'male';
	return 'female' if $lower eq 'f' || $lower eq 'female';
	return 'unknown';
}

1;

#!/bin/bash
## Written by Ed on 18.03.2024
clear
echo '###################################'
echo 'Laravel Installer'
echo 'Written in March, 2024'
echo '###################################'

#project name
while true; do
    # Prompt the user for the project name
    read -p "What is your preferred project name? " project_name

    # Check if the project name is empty
    if [ -z "$project_name" ]; then
        echo "Project name cannot be empty."
    elif [[ "$project_name" == *" "* ]]; then
            echo "Project name cannot contain spaces."
    elif [ -d "$project_name" ]; then
        echo "A directory with the name '$project_name' already exists."
    else
        break  # Exit the loop if project name is not empty and directory doesn't exist
    fi
done
#Run composer and get Silver Stripe
composer create-project laravel/laravel $project_name

cd $project_name

# Specify the patterns to be added to .gitignore
patterns="/node_modules
          /public/*
          /storage/*
          /vendor
          .env
          .env.backup
          .phpunit.result.cache
          docker-compose.override.yml
          npm-debug.log
          yarn-error.log
          /.idea
          /.vscode"

#add DB details
clear
echo '################ MySQL Database Connection ################'
while true; do
    # Prompt the user for the host name
    read -p "What is your database hostname? " DB_HOST
    read -p "What is your database name? " DB_NAME
    read -p "What is your database username? " DB_USER
    read -p "What is your database password? " DB_PASS

    # Specify the path to the .env file
    ENV_FILE=".env"

    # Check if the .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: .env file not found at $ENV_FILE"
        exit 1
    fi

    # Remove the specified lines from the .env file
    sed -i '/^# DB_HOST=127\.0\.0\.1$/d' "$ENV_FILE"
    sed -i '/^# DB_PORT=3306$/d' "$ENV_FILE"
    sed -i '/^# DB_DATABASE=laravel$/d' "$ENV_FILE"
    sed -i '/^# DB_USERNAME=root$/d' "$ENV_FILE"
    sed -i '/^# DB_PASSWORD=$/d' "$ENV_FILE"

    # Add missing lines to the .env file
    if ! grep -q "^DB_CONNECTION=" "$ENV_FILE"; then
        echo "DB_CONNECTION=$DB_CONNECTION" >> "$ENV_FILE"
    fi
    if ! grep -q "^DB_PORT=" "$ENV_FILE"; then
        echo "DB_PORT=3306" >> "$ENV_FILE"
    fi
    if ! grep -q "^DB_HOST=" "$ENV_FILE"; then
        echo "DB_HOST=" >> "$ENV_FILE"
    fi
    if ! grep -q "^DB_DATABASE=" "$ENV_FILE"; then
        echo "DB_DATABASE=" >> "$ENV_FILE"
    fi
    if ! grep -q "^DB_USERNAME=" "$ENV_FILE"; then
        echo "DB_USERNAME=" >> "$ENV_FILE"
    fi
    if ! grep -q "^DB_PASSWORD=" "$ENV_FILE"; then
        echo "DB_PASSWORD=" >> "$ENV_FILE"
    fi

    # Replace the values in the .env file
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" "$ENV_FILE"
    sed -i "s/DB_PORT=.*/DB_PORT=3306/" "$ENV_FILE"
    sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" "$ENV_FILE"
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" "$ENV_FILE"
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" "$ENV_FILE"
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" "$ENV_FILE"


    # Attempt to connect to the database using Laravel Artisan
    php artisan migrate:fresh > /dev/null 2>&1

    # Check the exit status
    if [ $? -eq 0 ]; then
        echo "Laravel database connection successful"
        break
    else
        echo "Error: Failed to connect to the Laravel database"
    fi
done

#install laravel breeze
composer require laravel/breeze --dev
COMMAND="@php artisan breeze:install --dark blade"
sed -i "/\"post-update-cmd\": \[/a\ \ \ \ \"$COMMAND\"," "composer.json"

#install laravel sanctum
composer require laravel/sanctum

#Update composer
echo 'Updating Composer'
composer update

#remove laravel breeze install command
sed -i "/$COMMAND/d" "composer.json"

#install other packages
composer require owen-it/laravel-auditing
composer require spatie/laravel-html
composer require yajra/laravel-datatables:^11.0
composer require yajra/laravel-datatables-buttons:^11.0

# Specify the path to your PHP file
PHP_FILE="config/app.php"

# Lines to add
LINES=(
    "    OwenIt\\Auditing\\AuditingServiceProvider::class,"
    "    Spatie\\Html\\HtmlServiceProvider::class,"
    "    Yajra\\DataTables\\DataTablesServiceProvider::class,"
    "    Yajra\\DataTables\\ButtonsServiceProvider::class,"
)

# Add the lines after the specified line in the PHP file
for LINE in "${LINES[@]}"; do
    LINE=$(echo "$LINE" | sed 's/\\/\\\\/g') # Escape backslashes
    sed -i "/'providers' => ServiceProvider::defaultProviders()->merge(\[/a $LINE" "$PHP_FILE"
    echo "Added: $LINE"
done

# Lines to add
LINES=(
    "    'DataTables' => Yajra\DataTables\Facades\DataTables::class,"
    "    'Html' => Spatie\Html\Facades\Html::class,"
)

# Add the lines after the specified line in the PHP file
for LINE in "${LINES[@]}"; do
    LINE=$(echo "$LINE" | sed 's/\\/\\\\/g') # Escape backslashes
    sed -i "/'aliases' => Facade::defaultAliases()->merge(\[/a $LINE" "$PHP_FILE"
    echo "Added: $LINE"
done

clear
while true; do
    # Prompt the user for the client name
    read -p "What is the client name? " client_name

    # Check if the client name is empty
    if [ -z "$client_name" ]; then
        echo "Client name cannot be empty."
    else
        # Line to add
        LINE="    'company' => env('APP_COMPANY', '$client_name'),"
        # Add the line after the 'return [' statement in the PHP file
        sed -i "/return \[/a $LINE" "$PHP_FILE"
        break
    fi
done

#get Laravel base
git clone https://github.com/thelogicstudio/laravel-base.git
cp -R laravel-base/* .
rm -rf laravel-base/

clear
#Add scripts to composer
#Specify the path to your composer.json file
COMPOSER_JSON_FILE="composer.json"

# Commands to add
COMMANDS=(
    "@php artisan db:seed --class=UserRoleSeeder"
    "@php artisan db:seed --class=PrivilegeRoleSeeder"
    "@php artisan db:seed --class=PrivilegeSeeder"
    "@php artisan db:seed --class=RoleSeeder"
    "@php artisan db:seed --class=UserSeeder"
    "@php artisan migrate"
    "@php artisan vendor:publish --provider=\\\"OwenIt\\\Auditing\\\AuditingServiceProvider\\\" --tag=migrations"
    "@php artisan vendor:publish --provider=\\\"OwenIt\\\Auditing\\\AuditingServiceProvider\\\" --tag=config"
    "@php artisan vendor:publish --tag=datatables-buttons"
    "@php artisan vendor:publish --tag=datatables"
)

# Add each command after "post-update-cmd" in composer.json
for COMMAND in "${COMMANDS[@]}"; do


    COMMAND=$(echo "$COMMAND" | sed 's/\\/\\\\/g') # Escape backslashes
    sed -i "/\"post-update-cmd\": \[/a\ \ \ \ \"$COMMAND\"," "$COMPOSER_JSON_FILE"

    echo "Added: $COMMAND"
done

#add Helper file
# Line to add
LINE='"files": ["app/Helpers/route.php"],'

# Add the line under "autoload" in composer.json
sed -i '/"autoload": {/a\ \ \ \ '"$LINE"'' "$COMPOSER_JSON_FILE"

echo "Added: $COMPOSER_JSON_FILE"

#update composer
composer update

# Remove each command from "post-update-cmd" in composer.json
# Commands to remove
COMMANDS=(
    "@php artisan vendor:publish --provider=\\\"OwenIt\\\Auditing\\\AuditingServiceProvider\\\" --tag=migrations"
    "@php artisan vendor:publish --provider=\\\"OwenIt\\\Auditing\\\AuditingServiceProvider\\\" --tag=config"
    "@php artisan vendor:publish --tag=datatables"
    "@php artisan vendor:publish --tag=datatables-buttons"
    "@php artisan migrate"
    "@php artisan db:seed --class=UserSeeder"
    "@php artisan db:seed --class=RoleSeeder"
    "@php artisan db:seed --class=PrivilegeSeeder"
    "@php artisan db:seed --class=PrivilegeRoleSeeder"
    "@php artisan db:seed --class=UserRoleSeeder"
)

for COMMAND in "${COMMANDS[@]}"; do
    sed -i "/\"$COMMAND\",/d" "$COMPOSER_JSON_FILE"
    echo "Removed: $COMMAND"
done

# Remove lines containing "artisan vendor:publish" from composer.json
sed -i '/artisan vendor:publish --provider/d' "$COMPOSER_JSON_FILE"


echo '########################'
echo 'All Done.'
echo 'Make sure you run following commands in your developer terminal'
echo 'npm install'
echo 'npm run dev (2 times)'
echo 'php artisan serve'
echo 'You can run npm run watch to use Browsersync'
echo 'default user is admin@abc.com'
echo 'default password is admin123'
echo 'Enjoy!'
echo '########################'
pause() {
    read -p "Press Enter to continue..."
}
pause
clear


# Playven admin API Documentation

  This page includes our admin API documentation and style guide on how to write your API documentation.

  Please pay attention to how you write it as it will be vital for others working to clearly understand how it works.
  Especially in cases where the other person might be a frontend developer with no knowledge of our backend.

## Table of Contents
  1. [Style Guide](#style-guide)
  1. [Registration API](#registration-api)
      1. [Sign UP API](#sign-up-api)
      1. [Confirm Administrator API](#confirm-administrator-api)
      1. [Reset Password API](#reset-password-api)
      1. [Change password after reset API](#change-password-after-reset-api)
  1. [Coach Registration API](#registration-api)
      1. [Sign UP API](#sign-up-api-1)
      1. [Confirm Coach API](#confirm-coach-api)
      1. [Reset Password API](#reset-password-api-1)
      1. [Change password after reset API](#change-password-after-reset-api-1)
  1. [Coaches API](#coaches-api)
      1. [Index API](#coaches-index-api)
      1. [Show API](#coaches-show-api)
      1. [Create API](#coaches-create-api)
      1. [Update API](#coaches-update-api)
      1. [Permissions API](#coaches-permissions-api)
      1. [Delete API](#coaches-delete-api)
      1. [Delete Many API](#coaches-delete-many-api)
      1. [Select Options API](#coaches-select-options-api)
      1. [Available Select Options API](#coaches-available-select-options-api)
  1. [Coaches Price Rates API](#coaches-price-rates-api)
      1. [Index API](#coaches-price-rates-index-api)
      1. [Show API](#coaches-price-rates-show-api)
      1. [Create API](#coaches-price-rates-create-api)
      1. [Create Many API](#coaches-price-rates-create-many-api)
      1. [Update API](#coaches-price-rates-update-api)
      1. [Delete API](#coaches-price-rates-delete-api)
      1. [Delete Many API](#coaches-price-rates-delete-many-api)
  1. [Coaches Salary Rates API](#coaches-salary-rates-api)
      1. [Index API](#coaches-salary-rates-index-api)
      1. [Show API](#coaches-salary-rates-show-api)
      1. [Create API](#coaches-salary-rates-create-api)
      1. [Update API](#coaches-salary-rates-update-api)
      1. [Delete API](#coaches-salary-rates-delete-api)
      1. [Delete Many API](#coaches-salary-rates-delete-many-api)
  1. [Coaches Reports API](#coaches-reports-api)
      1. [Index API](#coaches-reports-index-api)
  1. [Coaches Reservations API](#coaches-reservations-api)
      1. [Index API](#coaches-reservations-index-api)
  1. [Company API](#company-api)
      1. [Create API](#create-api)
      1. [Show API](#show-api)
  1. [Invoices API](#invoices-api)
      1. [Index API](#index-api)
      1. [Create API](#create-api-1)
      1. [Create Drafts API](#create-drafts-api)
  1. [Custom Emails API](#custom-emails-api)
      1. [Index API](#index-api-1)
  1. [Venues API](#venues-api)
      1. [Show API](#show-api-1)
      1. [Update API](#update-api)
  1. [Users API](#users-api)
      1. [Index API](#index-api-2)
      1. [Show API](#show-api-2)
      1. [Create API](#create-api-2)
      1. [Update API](#update-api-1)
      1. [Delete API](#delete-api)
      1. [Import API](#import-api)
  1. [Memberships API](#memberships-api)
      1. [Index API](#memberships-index-api)
      1. [Show API](#memberships-show-api)
      1. [Create API](#memberships-create-api)
      1. [Update API](#memberships-update-api)
      1. [Destroy API](#memberships-destroy-api)
      1. [Destroy Many API](#memberships-destroy-many-api)
      1. [Import API](#import-api-1)
  1. [Reservations API](#reservations-api)
      1. [Index API](#reservations-index-api)
      1. [Show API](#reservations-show-api)
      1. [Create API](#reservations-create-api)
      1. [Update API](#reservations-update-api)
      1. [Copy API](#reservations-copy-api)
      1. [Toggle Resell State](#reservations-toggle-resell-state)
      1. [Resell To User](#reservations-resell-to-user)
      1. [Destroy](#reservations-destroy)
      1. [Mark Salary Paid Many API](#reservations-mark-salary-paid-many)
  1. [Reports API](#reports-api)
      1. [Download Sales Report API](#download-sales-report-api)
      1. [Download Invoices Report API](#download-invoices-report-api)
      1. [Payment Transfers API pdf](#payment-transfers-api-pdf)
  1. [User Invoices API](#user-invoices-api)
      1. [Index API](#index-api-3)
  1. [Reservations API](#reservations-api)
      1. [Future Reservations API](#future-reservations-api)
  1. [Groups API](#groups-api)
      1. [Index API](#index-api-3)
      1. [Show API](#show-api-3)
      1. [Create API](#create-api-2)
      1. [Update API](#update-api-2)
      1. [Delete API](#delete-api-1)
      1. [Delete Many API](#delete-many-api)
      1. [Duplicate Many API](#duplicate-many-api)
  1. [Group Classifications API](#group-classifications-api)
      1. [Index API](#index-api-4)
      1. [Show API](#show-api-4)
      1. [Create API](#create-api-3)
      1. [Update API](#update-api-3)
      1. [Delete API](#delete-api-2)
      1. [Delete Many API](#delete-many-api-1)
  1. [Group Custom Billers API](#group-custom-billers-api)
      1. [Index API](#index-api-5)
      1. [Show API](#show-api-5)
      1. [Create API](#create-api-4)
      1. [Update API](#update-api-4)
      1. [Delete API](#delete-api-3)
      1. [Delete Many API](#delete-many-api-2)
      1. [Groups options API](#groups-options-api)
  1. [Group Subscriptions API](#group-subscriptions-api)
      1. [Index API](#index-api-6)
      1. [Delete API](#delete-api-4)
      1. [Delete Many API](#delete-many-api-3)
      1. [Mark Paid Many API](#mark-paid-many-api)
      1. [Mark Unpaid Many API](#mark-unpaid-many-api)
  1. [Group Reservations API](#group-reservations-api)
      1. [Index API](#index-api-7)
  1. [Group Members API](#group-members-api)
      1. [Index API](#index-api-8)
      1. [Show API](#show-api-6)
      1. [Create API](#create-api-5)
      1. [Delete API](#delete-api-5)
      1. [Delete Many API](#delete-many-api-4)
  1. [Participations API](#participations-api)
      1. [Index API](#index-api-9)
      1. [Show API](#show-api-7)
      1. [Create API](#create-api-6)
      1. [Delete API](#delete-api-6)
      1. [Delete Many API](#delete-many-api-5)
      1. [Mark Paid Many API](#mark-paid-many-api-1)


# Style Guide

  When creating API Documentation for your API Endpoint it should include the following things:

  * URL for the Endpoint
  * Method of Endpoint (POST/PUT/GET/DELETE)/PATCH)
  * Request Body
  * Success Response
  * Error Response including status code and content and causes for these

  Abiding these simple rules will keep our API Documentation clean and easy to use for everyone.

  Yay!


# Registration API

  Listed below are registration related API endpoints.<br/>
  This API requires authenticated admin.

## Sign UP API
  Creates admin with :god level.<br />
  Returns auth json data.<br />
  This API does not require authenticated admin.

  * **URL**

    /auth/admins

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      admin: {
        password: 'password',
        password_confirmation: 'password',
        birth_date: '15/03/1956',
        admin_ssn: '311280-888Y',
        email: 'test@test.test',
        first_name: John,
        last_name: 'Doe',
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ auth_token: '...' }`

  * **Error Response:**

    If invalid data:

    * **Code:** 422 <br />
      **Content:** `{ "errors": { "first_name": [ "cannot be blank" ] } }`


## Confirm Administrator API
  Confirms admin and changes password.
  Confirmation email will have param `needs_to_setup_password`, if it is true then frontend should send password params.

  * **URL**
    /auth/admins/confirmation.json

  * **Method:**
    `GET`

  *  **Request Body:**

    ```
      {
        password: '...', # if got :needs_to_setup_password
        password_confirmation: '...', # if got :needs_to_setup_password
        confirmation_token: '...'
      }
    ```

  * **Success Response**

    **Code:** 200
    **Content:** {"auth_token": "...", message": "Administrator account confirmed"}

  * **Error Response:**

    If token is invalid:

    * **Code:** 422 <br />
      **Content:** `{"errors": {"confirmation_token": [ "is invalid" ] }}`

    If password confirmation doesn't match:

    * **Code:** 422 <br />
      **Content:** `{"errors": {"password_confirmation": [ "doesn't match Password" ] }}`


## Reset Password API

  * **URL**

    /auth/admins/password.json

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      admin: {
        email: 'example@mail.com'
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **No content**

  * **Error Response:**

    * **Code:** 422 <br />
      **Content:** `{"errors":{"email":["not found"]}}`


## Change password after reset API
  Changes password after reset

  * **URL**
    /auth/admins/password.json

  * **Method:**
    `PUT or PATCH`

  *  **Request Body:**

  ```
    {
      admin: {
        password: '...',
        password_confirmation: '...',
        reset_password_token: '...'
      }
    }
  ```

  * **Success Response**

    **Code:** 200
    **Content:** {"auth_token": "..."}

  * **Error Response:**

    If token is invalid:

    * **Code:** 422 <br />
      **Content:** `{"errors":{"reset_password_token":["is not valid"]}}`

    If password confirmation doesn't match:

    * **Code:** 422 <br />
      **Content:** `{"errors":{"password_confirmation"=>["doesn't match Password"]}}`



# Coach Registration API
  Listed below are coach registration related API endpoints.<br/>
  This API does not require authenticated admin or coach.

## Sign UP API
  Creates coach with :base level.<br />
  Returns auth json data.<br />

  * **URL**

    /auth/coaches

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      coach: {
        password: 'password',
        password_confirmation: 'password',
        email: 'test@test.test',
        first_name: John,
        last_name: 'Doe',
        phone_number: '000-00-00',
        address: 'Some street'
        experience: 2,
        description: '...',
        clock_type: '12h',
        sports: ['tennis', 'squash'],
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ auth_token: '...' }`

  * **Error Response:**

    If invalid data:

    * **Code:** 422 <br />
      **Content:** `{ "errors": { "first_name": [ "cannot be blank" ] } }`


## Confirm Coach API
  Confirms coach and changes password.
  Confirmation email will have param `needs_to_setup_password`, if it is true then frontend should send password params.

  * **URL**
    /auth/coaches/confirmation.json

  * **Method:**
    `GET`

  *  **Request Body:**

    ```
      {
        password: '...', # if got :needs_to_setup_password
        password_confirmation: '...', # if got :needs_to_setup_password
        confirmation_token: '...'
      }
    ```

  * **Success Response**

    **Code:** 200
    **Content:** {"auth_token": "...", "message": "Coach account confirmed"}

  * **Error Response:**

    If token is invalid:

    * **Code:** 422 <br />
      **Content:** `{"errors": {"confirmation_token": [ "is invalid" ] }}`

    If password confirmation doesn't match:

    * **Code:** 422 <br />
      **Content:** `{"errors": {"password_confirmation": [ "doesn't match Password" ] }}`


## Reset Password API

  * **URL**

    /auth/coaches/password.json

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      coach: {
        email: 'example@mail.com'
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **No content**

  * **Error Response:**

    * **Code:** 422 <br />
      **Content:** `{"errors":{"email":["not found"]}}`


## Change password after reset API
  Changes password after reset.

  * **URL**
    /auth/coaches/password.json

  * **Method:**
    `PUT or PATCH`

  *  **Request Body:**

  ```
    {
      coach: {
        password: '...',
        password_confirmation: '...',
        reset_password_token: '...'
      }
    }
  ```

  * **Success Response**

    **Code:** 200
    **Content:** {"auth_token": "..."}

  * **Error Response:**

    If token is invalid:

    * **Code:** 422 <br />
      **Content:** `{"errors":{"reset_password_token":["is not valid"]}}`

    If password confirmation doesn't match:

    * **Code:** 422 <br />
      **Content:** `{"errors":{"password_confirmation"=>["doesn't match Password"]}}`



# Coaches API
  Listed below are Coaches API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API

  Returns JSON data.<br />

  * **URL**

    /admin/companies/coaches

  * **Method:**

    `GET`

  *  **Request Body**

  ```
    {
      with_outstanding_balance: true # optional, for invoices creation
    }
  ```

with_outstanding_balance

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        coaches: [
          {
            id:                       3,
            first_name:               'name',
            last_name:                'lastname',
            email:                    'example@mail.test',
            phone_number:             '000-00020002',
            address:                  'Some address',
            image:                    '...',
            experience:               3,
            description:              '...',
            level:                    'base',
            clock_type:               '24h,
            sports:                   ['tennis', 'squash'],
            permissions:              { ... # look up Coach permissions API},
            created_at:               '...',
            updated_at:               '...',
          },
          ...
        ],
        pagination: {
          current_page: 1,
          per_page: 10,
          total_pages: 13
        },
      }
  ```


## Show API
  Returns json data.

  * **URL**

    /admin/companies/coaches/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id:                       3,
        first_name:               'name',
        last_name:                'lastname',
        email:                    'example@mail.test',
        phone_number:             '000-00020002',
        address:                  'Some address',
        image:                    '...',
        experience:               3,
        description:              '...',
        level:                    'manager',
        clock_type:               '24h,
        sports:                   ['tennis', 'squash'],
        permissions:              { ... # look up Coach permissions API},
        created_at:               '...',
        updated_at:               '...',
      }
  ```

  * **Error Response:**

    If coach not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Create API
  Returns JSON data.

  * **URL**

    /admin/companies/coaches

  * **Method:**

    `POST`

  *  **Request Body**

  ```
    {
      "coach": {
        first_name:               'name',
        last_name:                'lastname',
        email:                    'example@mail.test',
        phone_number:             '000-00020002',
        address:                  'Some address',
        experience:               3,
        description:              '...',
        level:                    ‘base’, # or ‘editor’ or ‘manager’,
        clock_type:               '24h,
        sports:                   ['tennis', 'squash'],
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content:** See Show API response

  * **Error Response:**

    If create validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { first_name: ["can't be blank"] } }`


## Update API
  Returns JSON data.

  * **URL**

    /admin/companies/coaches/3

  * **Method:**

    `PUT`

  *  **Request Body**

  ```
    {
      "coach": {
        first_name:               'name',
        last_name:                'lastname',
        email:                    'example@mail.test',
        phone_number:             '000-00020002',
        address:                  'Some address',
        experience:               3,
        description:              '...',
        level:                    ‘base’, # or ‘editor’ or ‘manager’,
        clock_type:               '24h,
        sports:                   ['tennis', 'squash'],
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If coach not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { first_name: ["can't be blank"] } }`

## Permissions API
  Returns JSON data.

  * **URL**

    /admin/companies/coaches/3/permissions

  * **Method:**

    `PUT`

  *  **Request Body**

  ```
    {
      "coach": {
        permissions: {
          profile: ["read", "edit"],
          search: ["read", "edit"],
          dashboard: ["read", "edit"],
          calendar: ["read", "edit"],
          customers: ["read", "edit"],
          discounts: ["read", "edit"],
          recurring_reservations: ["read", "edit"],
          game_passes: ["read", "edit"],
          email_lists: ["read", "edit"],
          email_customization: ["read", "edit"],
          email_history: ["read", "edit"],
          groups: ["read", "edit"],
          group_classifications: ["read", "edit"],
          group_custom_billers: ["read", "edit"],
          coaches: ["read", "edit"],
          invoice_drafts: ["read", "edit"],
          invoice_unpaid: ["read", "edit"],
          invoice_paid: ["read", "edit"],
          invoice_create: ["read", "edit"],
          reports: ["read", "edit"],
          venues: ["read", "edit"],
          courts: ["read", "edit"],
          prices: ["read", "edit"],
          holidays: ["read", "edit"],
          colors: ["read", "edit"],
          company: ["read"],
          admins: ["read"],
          activity_logs: ["read", "edit"]
        }
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If coach not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { first_name: ["can't be blank"] } }`


## Delete API
  Returns JSON data.

  * **URL**

    /admin/companies/coaches/3

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If coach not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Delete Many API
  Returns JSON data.

  * **URL**

    /admin/companies/coaches

  * **Method:**

    `DELETE`

  *  **Request Body:** `{ coach_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `[1, 2]`


## Select Options API
  Returns JSON data.

  * **URL**

    /admin/companies/coaches/select_options

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `[{ value: 1, label: 'John Doe' }]`


## Available Select Options API
  Please note - this is a venue scope!
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/available_select_options

  * **Method:**

    `GET`

  *  **Request Body:**
  ```
    {
      court_id: 1,
      start_time: "02/06/2017 10:00",
      end_time: "02/06/2017 11:00",
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `[{ value: 1, label: 'John Doe' }]`



# Coaches Price Rates API
  Listed below are Coach Price Rates API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API
  Returns JSON data

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates

  * **Method:**

    `GET`

  *  **Request Body**

  ```
    {
      date: "02/06/2017",
      sport: "tennis",
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        price_rates: [
          {
            id: 3,
            coach_id: 3,
            venue_id: 3,
            start_time: "2017-06-02T19:00:00.000Z",
            end_time: "2017-06-02T20:00:00.000Z",
            sport_name: "tennis",
            rate: "10.0",
            created_at: "2017-06-01T17:07:37.451Z",
            updated_at: "2017-06-01T17:07:37.451Z"
          },
          ...
        ],
        pagination: {
          current_page: 1,
          per_page: 10,
          total_pages: 13
        },
      }
  ```


## Show API
  Returns json data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id: 3,
        coach_id: 3,
        venue_id: 3,
        start_time: "2017-06-02T19:00:00.000Z",
        end_time: "2017-06-02T20:00:00.000Z",
        sport_name: "tennis",
        rate: "10.0",
        created_at: "2017-06-01T17:07:37.451Z",
        updated_at: "2017-06-01T17:07:37.451Z"
      }
  ```

  * **Error Response:**

    If price rate not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Create API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates

  * **Method:**

    `POST`

  *  **Request Body**

  ```
    {
      "price_rate": {
        start_time: "02/06/2017 10:00",
        end_time: "02/06/2017 19:00",
        sport_name: "tennis",
        rate: "10.0",
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content:** See Show API response

  * **Error Response:**

    If create validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { rate: ["can't be blank"] } }`

    If has conflicts:
    * **Code:** 422 <br />
      **Content:** `{ errors: { start_time: ["overlapping with other price rates"], conflicts: [["01/01/2017 12:00 - 01/01/2017 13:00"]]} }`


## Create Many API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates/create_many

  * **Method:**

    `POST`

  *  **Request Body**

  ```
    {
      sport_name: "tennis",
      rate: "10.0",
      times: [
        {
          start_time: "02/06/2017 10:00",
          end_time: "02/06/2017 19:00",
        },
        {
          start_time: "03/06/2017 10:00",
          end_time: "03/06/2017 19:00",
        },
        ...
      ]
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content:** See Index API response

  * **Error Response:**

    If create validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { "01/01/2017 12:00 - 01/01/2017 13:00" => { rate: ["can't be blank"] } } }`

    If has conflicts:
    * **Code:** 422 <br />
      **Content:** `{ errors: { "01/01/2017 12:00 - 01/01/2017 13:00" => { start_time: ["overlapping with other price rates"], conflicts: [["01/01/2017 12:00 - 01/01/2017 13:00"]]} } }`


## Update API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates/3

  * **Method:**

    `PUT`

  *  **Request Body**

  ```
    {
      "coach": {
        start_time: "02/06/2017 10:00",
        end_time: "02/06/2017 19:00",
        sport_name: "tennis",
        rate: "10.0",
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If price rate not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { rate: ["can't be blank"] } }`

    If has conflicts:
    * **Code:** 422 <br />
      **Content:** `{ errors: { start_time: ["overlapping with other price rates"], conflicts: [["01/01/2000 12:00 - 01/01/2000 13:00"]]} }`


## Delete API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates/3

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If price rate not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Delete Many API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/price_rates

  * **Method:**

    `DELETE`

  *  **Request Body:** `{ price_rate_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `[1, 2]`



# Coaches Salary Rates API
  Listed below are Coach Salary Rates API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API
  Returns JSON data

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/salary_rates

  * **Method:**

    `GET`

  *  **Request Body**

  ```
    {
      sport: "tennis",
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        salary_rates: [
          {
            id: 3,
            coach_id: 3,
            venue_id: 3,
            start_time: "2000-01-01T19:00:00.000Z",
            end_time: "2000-01-01T20:00:00.000Z",
            weekdays: ['monday', 'tuesday'],
            sport_name: "tennis",
            rate: "10.0",
            created_at: "2017-06-01T17:07:37.451Z",
            updated_at: "2017-06-01T17:07:37.451Z"
          },
          ...
        ],
        pagination: {
          current_page: 1,
          per_page: 10,
          total_pages: 13
        },
      }
  ```


## Show API
  Returns json data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/salary_rates/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id: 3,
        coach_id: 3,
        venue_id: 3,
        start_time: "2000-01-01T19:00:00.000Z",
        end_time: "2000-01-01T20:00:00.000Z",
        weekdays: ['monday', 'tuesday'],
        sport_name: "tennis",
        rate: "10.0",
        created_at: "2017-06-01T17:07:37.451Z",
        updated_at: "2017-06-01T17:07:37.451Z"
      }
  ```

  * **Error Response:**

    If price rate not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Create API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/salary_rates

  * **Method:**

    `POST`

  *  **Request Body**

  ```
    {
      "salary_rate": {
        start_time: "10:00",
        end_time: "19:00",
        weekdays: ['monday', 'tuesday']
        sport_name: "tennis",
        rate: "10.0",
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content:** See Show API response

  * **Error Response:**

    If create validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { rate: ["can't be blank"] } }`

    If has conflicts:
    * **Code:** 422 <br />
      **Content:** `{ errors: { start_time: ["overlapping with other salary rates"], conflicts: [["01/01/2000 12:00 - 01/01/2000 13:00"]]} }`

## Update API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/salary_rates/3

  * **Method:**

    `PUT`

  *  **Request Body**

  ```
    {
      "coach": {
        start_time: "10:00",
        end_time: "19:00",
        weekdays: ['monday', 'tuesday']
        sport_name: "tennis",
        rate: "10.0",
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If price rate not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: { rate: ["can't be blank"] } }`

    If has conflicts:
    * **Code:** 422 <br />
      **Content:** `{ errors: { start_time: ["overlapping with other salary rates"], conflicts: [["01/01/2000 12:00 - 01/01/2000 13:00"]]} }`

## Delete API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/salary_rates/3

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If price rate not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Delete Many API
  Returns JSON data.

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/salary_rates

  * **Method:**

    `DELETE`

  *  **Request Body:** `{ salary_rate_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `[1, 2]`



# Coaches Reports API
  Listed below are Coach Reports API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API
  Returns JSON data

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/reports

  * **Method:**

    `GET`

  *  **Request Body**

  ```
    {
      sport: "tennis",
      start_date: '1/10/2017',
      end_date: '24/10/2017',
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

```
  {
    salary: {
      reservations: [
        {
          id: 2,
          user_id: 2,
          user_type: "User",
          court_id: 1,
          hours: 1.0,
          coach_salary: "10.0",
          coach_salary_paid: false,
          price: "20.0",
          start_time: "2017-06-13T12:00:00.000-07:00",
          end_time: "2017-06-13T13:00:00.000-07:00"
        }
      ],
      courts: [
        {
          id: 1, venue_id: 1, court_name: "Outdoor 1", sport_name: "tennis"
        }
      ]
    }
  }
```



# Coaches Reservations API
  Listed below are Coach Reservations API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API
  Returns JSON data:
    - coached reservations from all company venues json (from other venues or sports they will be grayed out on calendar)
    - unavailable slots, when all of this venue courts are booked, should be blocked on calendar
    - normalized courts for reservations json

  * **URL**

    /admin/venues/:venue_id/coaches/:coach_id/reservations

  * **Method:**

    `GET`

  *  **Request Body**

  ```
    {
      sport: "tennis",
      start_date: '1/10/2017',
      end_date: '24/10/2017',
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

```
  {
    reservations: [
      {
        id: 2,
        user_id: 2,
        user_type: "User",
        court_id: 1,
        color: "#f44336",
        start: "2017-06-20T12:00:00.000-07:00",
        end: "2017-06-20T13:00:00.000-07:00",
        user_name: "Play2 Ven2"
      }
    ],
    unavailable_slots: [
      {
        start: "2017-06-13T12:30:00.000-07:00",
        end: "2017-06-13T13:00:00.000-07:00"
      }
    ],
    courts: [
      {
        id: 1,
        court_description: "Court description 1",
        venue_id: 1,
        created_at: "2017-06-12T20:32:29.497Z",
        updated_at: "2017-06-12T20:32:29.497Z",
        duration_policy: "one_hour",
        start_time_policy: "any_start_time",
        active: true,
        indoor: false,
        index: 1,
        sport_name: "tennis",
        private: false,
        payment_skippable: false,
        surface: nil,
        custom_name: nil,
        sport: "Tennis",
        court_name: "Outdoor 1",
        shared_courts: []
      }
    ]
  }
```



# Company API

  Listed below are company related API endpoints.<br/>
  This API requires authenticated admin with :god level access.

## Create API
  Creates company and returns company JSON with updated admin auth payload. <br />

  * **URL**

    /admin/company

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      company: {
        bank_name: 'good bank',
        company_bic: '123413',
        company_business_type: 'LLC',
        company_city: 'Boston',
        company_iban: '12342341324',
        company_legal_name: 'company name',
        company_phone: '0(333)000-0000',
        company_street_address: 'street 1',
        company_tax_id: 2435234,
        company_website: 'playven.com',
        company_zip: 50000,
        country_id: 1,
        currency: 'EUR',
        invoice_sender_email: 'test@test.test',
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** See show API response +
  ```
    auth_payload: { auth_token: "..." }
  ```

  * **Error Response:**

    If validation error:

    * **Code:** 422 <br />
      **Content:** `{ "errors": { "company_legal_name": [ "can't be blank" ] } }`

    If failed to create Stripe account:

    * **Code:** 422 <br />
      **Content:** `{ "errors": { "stripe": [ "Unable to create account!" ] } }`

## Show API

  * **URL**

    /admin/company

  * **Method:**

    `GET`

  *  **Request Body:** empty

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    id: 1,
    bank_name: 'good bank',
    company_bic: '123413',
    company_business_type: 'LLC',
    company_city: 'Boston',
    company_iban: '12342341324',
    company_legal_name: 'company name',
    company_phone: '0(333)000-0000',
    company_street_address: 'street 1',
    company_tax_id: 2435234,
    company_website: 'playven.com',
    company_zip: 50000,
    country_id: 1,
    currency: 'EUR',
    invoice_sender_email: 'test@test.test',
    created_at: '',
    updated_at: '',
  ```

  * **Error Response:**

    If company not created yet:

    * **Code:** 404 <br />
      **Content:** `{ "errors": { 'Record not found' }`

    If admin without access:

    * **Code:** 401 <br />
      **Content:** `{ "errors": { 'Not enough permissions for that' }`


# Invoices API

  Listed below are company invoices related API endpoints.<br/>
  This API requires authenticated admin.

## Index API
  Returns invoices json data.<br />

  * **URL**

    /admin/invoices

  * **Method:**

    `GET`

  *  **Request Body:**
      -  supported `type` values: `paid`, `unpaid`, `drafts`

  ```
    {
      type: 'paid',
      search: 'John Doe',
      page: 1,
      per_page: 10,
      sort_on: 'customer_name'
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        invoices: [
          {
            id: 3,
            company_id: 1,
            is_draft: 'true',
            created_at: '...',
            updated_at: '...',
            total: '18.5',
            owner_id: 1,
            owner_type: 'User',
            is_paid: 'false',
            reference_number: '14123412',
            billing_time: '...',
            due_time: '...',
            pdf_url: 'http://playven.com/companies/1/invoices/3.pdf'
            user: { # can be empty for 'Coach' owner_type and vice versa
              id: 3,
              first_name: 'John',
              last_name: 'Doe',
              email: 'john-doe@test.mail',
              created_at: '...',
              updated_at: '...',
              image: 'http://cdn.com/25453.jpg',
            },
            coach: { ... }
          },
          ...
        ],
        pagination: {
          current_page: 1,
          per_page: 10,
          total_pages: 13
        },
        summary: {
          paid_count: 2,
          unpaid_count: 3,
          drafts_count: 1
        }
      }
  ```


## Show API
  Returns invoice JSON data.<br />

  * **URL**

    /admin/invoices/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id: 1,
        company_id: 1,
        is_draft: true,
        total: "0.0",
        owner_id: 1,
        owner_type: 'User',
        is_paid: false,
        reference_number: "95490 45323",
        billing_time: "2017-05-24T04:23:58.357-07:00",
        due_time: "2017-05-24T17:00:00.000-07:00",
        pdf_url: "http://test.host/companies/1/invoices/1.pdf",
        created_at: "2017-05-24T11:24:00.020Z",
        updated_at: "2017-05-24T11:24:00.020Z",
        owner: { first_name... # user JSON },
        custom_invoice_components: [
          {
            id: 1,
            invoice_id: 2,
            price: '33',
            is_billed: true,
            is_paid: false,
            name: 'Venue fee',
            vat_decimal: '0.1',
            created_at: '...',
            updated_at: '...',
          }
        ],
        gamepass_invoice_components: [
          {
            id: 1,
            invoice_id: 2,
            price: '33',
            is_billed: true,
            is_paid: false,
            auto_name: 'Summer pass',
            price_with_currency: '$22',
            created_at: '...',
            updated_at: '...',
          }
        ],
        invoice_components: [
          {
            id: 1,
            invoice_id: 2,
            price: '33',
            is_billed: true,
            is_paid: false,
            is_canceled: false,
            start_time: '...',
            end_time: '...',
            court_name: 'Indoor1',
            created_at: '...',
            updated_at: '...',
          }
        ],
        participation_invoice_components: [
          {
            id: 1,
            invoice_id: 2,
            price: '33',
            is_billed: true,
            is_paid: false,
            start_time: '...',
            end_time: '...',
            court_name: 'Indoor1',
            group_name: 'Falcons'
            created_at: '...',
            updated_at: '...',
          }
        ],
        group_subscription_invoice_components: [
          {
            id: 1,
            invoice_id: 2,
            price: '33',
            is_billed: true,
            is_paid: false,
            start_date: '2017-05-24',
            end_date: '2017-06-24',
            group_name: 'Falcons'
            created_at: '...',
            updated_at: '...',
          }
        ]
      }
  ```


## Create API
  Creates custom component invoices for requested user. Only custom component invoices are supported. <br />
  See 'Users Index API' as the source of user ids.

  * **URL**

    /admin/invoices/create

  * **Method:**

    `POST`

  *  **Request Body:**
      - `owner_id` and `owner_type` is required
      - `vat_decimal` in `custom_invoice_components_attributes` is something like '0.1' (meaning 10%)
      - `name`, `price`, `vat_decimal` are required in `custom_invoice_components_attributes`

  ```
    {
      owner_id: 1,
      owner_type: 'User',
      custom_invoice_components_attributes: [
        {
          price: 10,
          name: 'custom',
          vat_decimal: '0.1'
        }
      ]
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**

    If no users found:

    * **Code:** 422 <br />
      **Content:** `{ "errors": { "owner_id": [ "cannot be nil" ] } }`

    If custom invoice doesn't pass validation:

    * **Code:** 422 <br />
      **Content:**
  ```
  {
     "errors": {
       "custom_invoice_components.price": [
         "can't be blank"
       ],
       "custom_invoice_components.name": [
         "can't be blank"
       ],
       "custom_invoice_components.vat_decimal": [
         "can't be blank"
       ]
     }
  }
  ```


## Create Drafts API
  Creates invoice drafts for requested users.<br />
  See 'Users Index API' as the source of user ids.

  * **URL**

    /admin/invoices/create_drafts

  * **Method:**

    `POST`

  *  **Request Body:**
      - if `user_type` is sent, it will create drafts for ALL users/coaches of this type with outstanding balances
      - supported `user_type` values: `membership_users`, `saved_users`, `recent_users`, `all_users`, `all_coaches`
      - it will update company recent users list with invoiced users
      - if `save_users` sent, it will add users to company saved invoice users list
      - `user_ids` have priority over `user_type`, and `coach_ids` have priority over both
      - if `custom_biller_id` sent it will associate new invoices with this biller
      - if `custom_biller_id` sent together with `user_type` it will create invoices only for users of this type with outstanding balances to this biller

  ```
    {
      user_ids: [1, 2, 3],
      coach_ids: [1, 2, 3], # has priority over `user_ids`
      start_date: '01/04/2018',
      end_date: '31/04/2018',
      user_type: '',
      save_users: false,
      custom_biller_id: 3, # optional
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        message: ['success', "3 invoices were generated successfully. Now review and send them."]
      }
  ```

  * **Error Response:**

    If no users found:

    * **Code:** 422 <br />
      **Content:** `{ message: ['error', Please select some users'] }`

    If no outstanding balance for user in requested time period:

    * **Code:** 422 <br />
      **Content:** `{ message: ['error', 'There's nothing to invoice for this period.'] }`

    If `custom_biller_id` sent but not found:

    * **Code:** 422 <br />
      **Content:** `{ errors: ['Record not found'] }`



# Custom Emails API
  Listed below are venue custom emails related API endpoints.<br/>
  This API requires authenticated admin.

## Index API
  Returns JSON data.<br />
  Accepts no parameters.<br />

  * **URL**

    /admin/venues/5/emails/custom_emails

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        custom_emails: [
          {
            id:                                   3,
            created_at:                           '23/2/1993 13:15',
            from:                                 'admin@test.mail',
            subject:                              'Example subject',
            body:                                 'mail body...',
            image_url:                            'http://cdn.com/25453.jpg',
            recipient_emails: ['recipient1@test.mail', 'listed_user1@test.mail']
          },
          ...
        ]
      }
  ```


# Venues API

  Listed below are venues related API endpoints.<br/>
  This API requires authenticated admin.

## Show API
  Returns venue JSON data.<br />

  * **URL**

    /admin/venues/1

  * **Method:**

    `GET`


  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id: 1,
        venue_name: 'example name',
        latitude: '123312',
        longitude: '123312',
        description: 'example description',
        parking_info: '...',
        transit_info: '...',
        website: 'playven.com',
        phone_number: '13241234',
        company_id: 1,
        created_at: '...',
        updated_at: '...',
        street: '...',
        city: '...',
        zip: '...',
        booking_ahead_limit: 34,
        listed: true,
        primary_photo_id: 1,
        cancellation_time: 24,
        invoice_fee: '2.5',
        allow_overlapping_resell: false,
        confirmation_message: '...',
        registration_confirmation_message: '...',
        max_consecutive_bookable_hours: 4,
        max_bookable_hours_per_day: 7,
        custom_colors: {
          unpaid: '#f44336',
          paid: '#4caf50',
          semi_paid: '#f8ac59',
          membership: nil,
          reselling: nil,
          invoiced: nil,
          other: '#eeeeee',
          guest_unpaid: nil,
          guest_paid: nil,
          guest_semi_paid: nil
        },
        user_colors: [
          { user_id: 1, color: '#123456' },
          ...
        ],
        discount_colors: [
          { discount_id: 1, color: '#123456' },
          ...
        ],
        business_hours: {
          mon: { opening: 0, closing: 52000 },
          tue: {...}
          ...
        },
        courts_count: 2,
        users_count: 34,
        primary_photo_url: 'https://cdn.com/12341314.jpg',
        photos: [
          {
            id: 1,
            full_url: 'https://cdn.com/12341314.jpg',
            thumb_url: 'https://cdn.com/12341314_t.jpg',
            image: 'https://cdn.com/12341314_t.jpg',
            primary: true
          },
          ...
        ],
        utilization: {
          metrics: 'hours',
          availability: '...',
          chart: [
            {
              from: '...',
              to: '...',
              availability: '...'
            },
            ...
          ]
        }
        revenue: {
          total: '100500.0',
          lost: 0
        }
      }
  ```

## Update API
  Updates venue and returns venue JSON.<br />
  `user_colors` and `discount_colors` - only updates colors for users/discounts sent in the arrays

  * **URL**

    /admin/venues/1

  * **Method:**

    `PATCH`

  *  **Request Body:**
      -  empty string/null sent for color will reset it to default

  ```
    {
        venue_name: 'example name',
        latitude: '123312',
        longitude: '123312',
        description: 'example description',
        parking_info: '...',
        transit_info: '...',
        website: 'playven.com',
        phone_number: '13241234',
        street: '...',
        city: '...',
        zip: '...',
        booking_ahead_limit: 34,
        listed: true,
        primary_photo_id: 1,
        cancellation_time: 24,
        invoice_fee: '2.5',
        allow_overlapping_resell: false,
        confirmation_message: '...',
        registration_confirmation_message: '...',
        max_consecutive_bookable_hours: 4,
        max_bookable_hours_per_day: 7,
        custom_colors: {
          unpaid: '#f44336',
          paid: '#4caf50',
          semi_paid: '#f8ac59',
          membership: '',
          reselling: nil,
          invoiced: nil,
          other: '#eeeeee',
          guest_unpaid: nil,
          guest_paid: nil,
          guest_semi_paid: nil
        },
        user_colors: [
          { user_id: 1, color: '#123456' },
          ...
        ],
        discount_colors: [
          { discount_id: 1, color: '#123456' },
          ...
        ]
        business_hours: {
          mon: { opening: 0, closing: 52000 },
          tue: {...}
          ...
        },
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
        - content same as Show API

  * **Error Response:**

    If venue not updated:

    * **Code:** 422 <br />
      **Content:** `{ errors: ["Venue name can't be blank"] }`


# Users API

  Listed below are Users API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API

  Returns JSON data.<br />

  * **URL**

    /admin/users

  * **Method:**

    `GET`

  *  **Request Body:**
    -  Accepts optional parameter: `with_outstanding_balance` which will scope returned users only to ones having outstanding balance
    -  it also supports query `user_type` values: `membership_users`, `saved_users`, `recent_users`, `all_users`(default)
    - if `custom_biller_id` sent together with `with_outstanding_balance` it will scope users of `user_type` with outstanding balances to this biller

  ```
    {
      type: 'paid',
      search: 'John Doe',
      page: 1,
      per_page: 10,
      sort_on: 'customer_name',
      with_outstanding_balance: false,
      user_type: 'all_users',
      custom_biller_id: '',
    }
  ```

  * **Success Response:**
      - discounts data returned if `venue_id` was sent

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        users: [
          {
            id:                       3,
            first_name:               'name',
            last_name:                'lastname',
            email:                    'example@mail.test',
            created_at:               '...',
            updated_at:               '...',
            image:                    '...',
            outstanding_balance:      13.5,
            lifetime_value:           134.1,
            discounts: [
              # see discounts show API
            ]
          },
          ...
        ],
        pagination: {
          current_page: 1,
          per_page: 10,
          total_pages: 13
        },
      }
  ```

## Show API
  Returns json data.
  Accepts optional parameters: `venue_id` <br />

  * **URL**

    /admin/users/3

  * **Method:**

    `GET`

  * **Success Response:**
      - discounts data returned if `venue_id` was sent

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id:                       3,
        first_name:               'name',
        last_name:                'lastname',
        email:                    'example@mail.test',
        created_at:               '...',
        updated_at:               '...',
        image:                    '...',
        outstanding_balance:      13.5,
        lifetime_value:           134.1,
        average_reservation_fee:  15.777,
        phone_number:             '1123456789',
        city:                     'Boston',
        street_address:           'Some address 4',
        zipcode:                  '12345',
        discounts: [
          # see discounts show API
        ]
      }
  ```

  * **Error Response:**

    If user not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`


## Create API
  Returns JSON data.
  If user with email already exists, connects it to company and returns JSON with existing user data.

  * **URL**

    /admin/users

  * **Method:**

    `POST`

  *  **Request Body**

  ```
    {
      "user": {
        first_name:           'John',
        last_name:            'Dow',
        email:                'example@mail.test',
        phone_number:         '1123456789',
        city:                 'Boston',
        street_address:       'Some address 4',
        zipcode:              '12345',
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** See Show API response

  * **Error Response:**
    If venue not created:
    * **Code:** 422 <br />
      **Content:** `{ errors: ['Create a venue first'] }`

    If create validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["First name can't be blank", ...] }`


## Update API
  Returns JSON data.
  If user with email already exists, connects it to company and returns JSON with existing user data. If possible, transfers data of user with incorrect email to existing user and deletes user with incorrect email.

  * **URL**

    /admin/users/3

  * **Method:**

    `PUT`

  *  **Request Body**

  ```
    {
      "user": {
        first_name:           'John',
        last_name:            'Dow',
        email:                'example@mail.test',
        phone_number:         '1123456789',
        city:                 'Boston',
        street_address:       'Some address 4',
        zipcode:              '12345',
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If customer not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If customer already confirmed:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't modify already confirmed customer"] }`

    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["First name can't be blank", ...] }`


## Delete API
  Returns JSON data.

  * **URL**

    /admin/users/3

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If customer not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`

    If customer already confirmed:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't modify already confirmed customer"] }`

    If customer related to other company:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't modify customer with relation to other companies"] }`

    If failed to delete:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't delete customer"] }`

## Import API
  Imports CSV data from file.

  * **URL**

    `/admin/venues/1/users/import`

  * **Method:**

    `POST`

  *  **Request Body(multipart/form-data)**

  ```
    {
      csv_file: '...'
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      report: {
        created_count: 1,
        skipped_count: 3,
        failed_count: 0,
        failed_rows: [
          {
            user: { '...base user json' }
            errors: ['First name can't be blank']
          },
          ...
        ]
      }
    }
  ```

  * **Error Response:**

    If no file sent:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Please select CSV file"] }`

    If venue_id wasn't specified:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Please select venue for import"] }`

    If venue wasn't found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`

    If invalid file:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Invalid file"] }`

    If failed to process file:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Failed to process CSV. Error: %{error}"] }`

    If incomplete csv data structure:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Invalid header. Missing columns: first_name"] }`


# Memberships API
  Listed below are Memberships API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API

  Returns JSON data.<br />

  * **URL**

    /admin/venues/1/memberships.json

  * **Method:**

    `GET`

  *  **Request Body:**
    -  Accepts optional parameter: `search` to filter results based on query
    –  Accepts `sort_on` parameter to order results. Possible values: `customer_name`, `weekday`, `time`, `end_time`,
       `start_time`, `user_id`, `created_at`, `updated_at`, `price`, `title`
    – Accepts `page` (integer) to paginate

  * **Success Response:**
    * **Code:** 200

  ```
    { "memberships": [
      {
        "id": 256,
        "user_id": 1588,
        "venue_id": 12,
        "created_at": "2016-12-22T17:10:07.748Z",
        "updated_at": "2016-12-22T17:10:07.748Z",
        "price": 18.0,
        "invoice_by_cc": false,
        "title": null,
        "note": null,
        "start_time": "2017-01-02T16:00:00.000+02:00",
        "end_time": "2017-05-21T17:00:00.000+03:00",
        "weekday": "monday",
        "user": {
          "id": 1588,
          "first_name": "Timo",
          "last_name": "Jokinen",
          "email": "timojokinen@playven.com",
          "created_at": "2016-12-22T17:10:06.855Z",
          "updated_at": "2016-12-22T17:10:06.855Z",
          "image": null,
          "clock_type": "24h"
        },
        "reservations": [
          {
            "id": 24881,
            "user_id": 1588,
            "date": "02/01/2017",
            "price": "18.0",
            "total": null,
            "created_at": "2016-12-22T17:10:07.756Z",
            "updated_at": "2016-12-22T17:10:07.756Z",
            "court_id": 39,
            "is_paid": false,
            "user_type": "User",
            "charge_id": null,
            "refunded": false,
            "payment_type": "unpaid",
            "booking_type": "membership",
            "note": null,
            "initial_membership_id": null,
            "reselling": false,
            "inactive": false,
            "billing_phase": "not_billed",
            "paid_in_full": false,
            "amount_paid": 0.0,
            "start_time": "2017-01-02T16:00:00.000+02:00",
            "end_time": "2017-01-02T17:00:00.000+02:00",
            "start_tact": "16:00",
            "end_tact": "17:00",
            "has_membership": true,
            "resold": false,
            "future": false,
            "refundable": false,
            "court": {
              "id": 39,
              "court_description": "",
              "venue_id": 12,
              "created_at": "2016-12-22T15:15:23.244Z",
              "updated_at": "2016-12-22T15:15:23.244Z",
              "duration_policy": "one_hour",
              "start_time_policy": "hour_mark",
              "active": true,
              "indoor": true,
              "index": 1,
              "sport_name": "tennis",
              "private": false,
              "payment_skippable": false,
              "surface": null,
              "custom_name": null,
              "sport": "Tennis",
              "court_name": "Indoor 1"
            }
          },
        ],
      "courts": [
        {
          "id": 39,
          "court_description": "",
          "venue_id": 12,
          "created_at": "2016-12-22T15:15:23.244Z",
          "updated_at": "2016-12-22T15:15:23.244Z",
          "duration_policy": "one_hour",
          "start_time_policy": "hour_mark",
          "active": true,
          "indoor": true,
          "index": 1,
          "sport_name": "tennis",
          "private": false,
          "payment_skippable": false,
          "surface": null,
          "custom_name": null,
          "sport": "Tennis",
          "court_name": "Indoor 1"
        }
      ],

      pagination: {
        current_page: 1,
        per_page: 10,
        total_pages: 2
      }
    }
  ```


## Show API

  * **URL**

    /admin/venues/1/memberships/1

  * **Method:**

    `GET`

  *  **Request Body:** empty

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      "id": 256,
      "user_id": 1588,
      "venue_id": 12,
      "created_at": "2016-12-22T17:10:07.748Z",
      "updated_at": "2016-12-22T17:10:07.748Z",
      "price": 18.0,
      "invoice_by_cc": false,
      "title": null,
      "note": null,
      "start_time": "2017-01-02T16:00:00.000+02:00",
      "end_time": "2017-05-21T17:00:00.000+03:00",
      "weekday": "monday",
      "user": {
        "id": 1588,
        "first_name": "Timo",
        "last_name": "Jokinen",
        "email": "timojokinen@playven.com",
        "created_at": "2016-12-22T17:10:06.855Z",
        "updated_at": "2016-12-22T17:10:06.855Z",
        "image": null,
        "clock_type": "24h"
      },
      "reservations": [
        {
          "id": 24881,
          "user_id": 1588,
          "date": "02/01/2017",
          "price": "18.0",
          "total": null,
          "created_at": "2016-12-22T17:10:07.756Z",
          "updated_at": "2016-12-22T17:10:07.756Z",
          "court_id": 39,
          "is_paid": false,
          "user_type": "User",
          "charge_id": null,
          "refunded": false,
          "payment_type": "unpaid",
          "booking_type": "membership",
          "note": null,
          "initial_membership_id": null,
          "reselling": false,
          "inactive": false,
          "billing_phase": "not_billed",
          "paid_in_full": false,
          "amount_paid": 0.0,
          "start_time": "2017-01-02T16:00:00.000+02:00",
          "end_time": "2017-01-02T17:00:00.000+02:00",
          "start_tact": "16:00",
          "end_tact": "17:00",
          "has_membership": true,
          "resold": false,
          "future": false,
          "refundable": false,
          "court": {
            "id": 39,
            "court_description": "",
            "venue_id": 12,
            "created_at": "2016-12-22T15:15:23.244Z",
            "updated_at": "2016-12-22T15:15:23.244Z",
            "duration_policy": "one_hour",
            "start_time_policy": "hour_mark",
            "active": true,
            "indoor": true,
            "index": 1,
            "sport_name": "tennis",
            "private": false,
            "payment_skippable": false,
            "surface": null,
            "custom_name": null,
            "sport": "Tennis",
            "court_name": "Indoor 1"
          }
        },
      ],
      "courts": [
        {
          "id": 39,
          "court_description": "",
          "venue_id": 12,
          "created_at": "2016-12-22T15:15:23.244Z",
          "updated_at": "2016-12-22T15:15:23.244Z",
          "duration_policy": "one_hour",
          "start_time_policy": "hour_mark",
          "active": true,
          "indoor": true,
          "index": 1,
          "sport_name": "tennis",
          "private": false,
          "payment_skippable": false,
          "surface": null,
          "custom_name": null,
          "sport": "Tennis",
          "court_name": "Indoor 1"
        }
      ]
    }
  ```

## Create API
  Creates new recurring reservation. <br />

  * **URL**

    /admin/venues/1/memberships

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      membership: {
        user: USER_OBJECT (see below)
        use_all_courts: true // if false/missing court_ids must present
        court_ids: [1,2,3] // can omit if use_all_courts present
        title: 'string',
        price: 30,
        note: 'text',
        ignore_overlapping_reservations: true // see below
        weekday: 'Monday', // or Tuesday, Sunday etc
        start_time: '13:00',
        start_date: '23/02/2017'
        end_time: '15:00',
        end_date: '23/03/2017',
      }
    }
  ```

  User object for existing user is:
  ```
    {
      email: 'hello@there.com'
    }
  ```
  For new user is:
  ```
    {
      first_name: 'john',
      last_name: 'dorian',
      email: 'jd@scrub.com'
      street_address: 'line1 line2'
      zipcode: '651341'
      city: 'Jorgie Town'
      phone_number: '+341134
      locale: 'fi'
    }
  ```

  `ignore_overlapping_reservations` indicates whether proceed or render error if
  any new reservation overlaps with existing. General workflow is:
  1) Send request with `ignore_overlapping_reservations = false`
  2) Check for overlapping errors, display them to user and ask if he wants to proceed
  (if he wants to ignore overlapping reservations and create those which do not overlap)
  3) Re-send the request with `ignore_overlapping_reservations = true` if user wants to.

  * **Success Response:**

    * **Code:** 201 <br />
      **Content:** See show API response

  * **Error Response:**

    If validation error:

    * **Code:** 422 <br />
      **Content:** `{ "errors": { "field_name": [ "array of errors" ] } }`

    If there's any invalid reservations (most likely overlapping reservations),
    root-level `reservation_errors` will present in the response:
  ```
    errors: { "field_name": [ ... ] },
    reservation_errors: {
      start_time: "2017-05-29 20:00:00 +0300",
      end_time: "2017-05-29 21:00:00 +0300",
      court_name: "Indoor 1",
      errors: ["Reservation cannot be created because King told them not to do so"]
    }
  ```

## Update API

  Updates a recurring reservation. <br />

  * **URL**

    /admin/venues/1/memberships/1

  * **Method:**

    `PATCH`

  Everything is the same as for Create action, but:
  1) You cannot modify user, so do not provide `user` hash.
  2) Success response code is 200 (was 201 for Create action)

## Destroy API

  Destroy a recurring reservation

  * **URL**

    /admin/venues/1/memberships/1

  * **Method:**

    `DELETE`

  * **Success Response:**

    Status: 200<br/>
    Content:

  ```
    [1] // array containing an ID of the deleted membership
  ```

## Destroy many API

  Destroy several recurring reservations at once.

  * **URL**

    /admin/venues/1/memberships

  * **Method:**

    `DELETE`

  * **Request body:**

  ```
    {
      membership_ids: [1,2,3]
    }
  ```

  * **Success Response:**

    Status: 200<br/>
    Content:
  ```
    [1, 2] // array containing ids of deleted memberships
  ```
## Import API
  Imports CSV data from file.

  * **URL**

    `/admin/venues/1/memberships/import`

  * **Method:**

    `POST`

  *  **Request Body(multipart/form-data)**
    -  if `ignore_conflicts` sent, it will ignore any recurring reservations with errors and create memberships without them

  ```
    {
      ignore_conflicts: false,
      csv_file: '...'
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      report: {
        created_count: 1,
        skipped_count: 3,
        failed_count: 0,
        failed_rows: [
          {
            params: { "email"=>"example@mail.com", "start_date"=>"11/01/2017", "end_date"=>"11/02/2017", "start_time"=>"10:00", "end_time"=>"11:00", "weekday"=>"tuesday", "price"=>10.0, "court_index"=>1, "court_outdoor"=>"Indoor", "court_type"=>"Indoor", "court_sport"=>"" },
            errors: ['Court 'Indoor1' not found.']
          },
          ...
        ]
      }
    }
  ```

  * **Error Response:**

    If no file sent:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Please select CSV file"] }`

    If venue_id wasn't specified:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Please select venue for import"] }`

    If venue wasn't found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found"] }`

    If invalid file:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Invalid file"] }`

    If failed to process file:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Failed to process CSV. Error: %{error}"] }`

    If incomplete csv data structure:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Invalid header. Missing columns: court_index"] }`


# Reservations API

## Index API
  URL: `admin/venues/1/reservations`

  Method: `GET`

  Request body: `{"start"=>"17/04/2017", "end"=>"18/04/2017"}`

  Response: 200

  Response body:

  ```
    [
      {
        "id": 62356,
        "start": "2017-05-26T09:30:00.000+03:00",
        "end": "2017-05-26T11:30:00.000+03:00",
        "price": "14.0",
        "amount_paid": "3.0",
        "title": "134",
        "resourceId": 39,
        "color": "#4caf50",
        "note": ""
      },
    ]
  ```

## Show API
  URL: `admin/venues/1/reservations/1`

  Method: `GET`

  Response: 200

  Response body:

  ```
  {
    "id": 62356,
    "user_id": 6202,
    "date": "26/05/2017",
    "price": "14.0",
    "total": null,
    "created_at": "2017-05-26T07:03:30.451Z",
    "updated_at": "2017-05-26T07:05:08.554Z",
    "court_id": 39,
    "is_paid": false,
    "user_type": "Guest",
    "charge_id": null,
    "refunded": false,
    "payment_type": "paid",
    "booking_type": "admin",
    "note": "",
    "initial_membership_id": null,
    "reselling": false,
    "inactive": false,
    "billing_phase": "not_billed",
    "paid_in_full": true,
    "amount_paid": 3.0,
    "start_time": "2017-05-26T09:30:00.000+03:00",
    "end_time": "2017-05-26T11:30:00.000+03:00",
    "start_tact": "09:30",
    "end_tact": "11:30",
    "has_membership": false,
    "resold": false,
    "future": false,
    "refundable": false,
    "court": {
      "id": 39,
      "court_description": "",
      "venue_id": 12,
      "created_at": "2016-12-22T15:15:23.244Z",
      "updated_at": "2016-12-22T15:15:23.244Z",
      "duration_policy": "one_hour",
      "start_time_policy": "hour_mark",
      "active": true,
      "indoor": true,
      "index": 1,
      "sport_name": "tennis",
      "private": false,
      "payment_skippable": false,
      "surface": null,
      "custom_name": null,
      "sport": "Tennis",
      "court_name": "Indoor 1"
    },
    "full_name": "134",
    "phone_number": null,
    "calculated_price": 14.0,
    "coach_ids": [1,2]
    "coaches": [{ # coach JSON ...}]
  }
  ```

## Create API

URL: `/admin/venues/1/reservations`

Method: `POST`

Request body:

  ```
    reservations: [ // array of reservations to create
      {
        court_id: 1,
        price: 10,
        start_tact: '13:00',
        end_tact: '14:00',
        date: '13/10/2017',
        coach_ids: [1,2], # optional
      }
    ],
    user: USER_OBJECT // see below
    meta: {
      note: 'not for all reservations',
    }

  ```

`USER_OBJECT` is one of the following:

Already existing user

  ```
    {
      type: 'User',
      id: 3
    }
  ```

Already existing group

  ```
    {
      type: 'Group',
      id: 1
    }
  ```

New user

  ```
    {
      type: 'User',
      first_name: 'John',
      last_name: 'Doe',
      email: 'hey@there.com',
      phone_number: '+341341',
      locale: 'fi'
    }
  ```

Guest user:

  ```
    {
      type: 'Guest',
      full_name: 'Hoe Boe'
    }
  ```

Success response: 201

Success body:

  ```
    {
      saved: [
        "id": 62356,
        "user_id": 6202,
        "date": "26/05/2017",
        "price": "14.0",
        ...
      ],
    }
  ```

  * Error response: 422

    * Error body:

  ```
    {
      saved: [
        "id": 62356,
        "user_id": 6202,
        "date": "26/05/2017",
        "price": "14.0",
        ...
      ],

      failed: [["Reservation #1 error 1", "Reservation #1 error 2"]]
    }
  ```

    if coach is unavailable:
      `failed: [['Coach unavailable']]`


## Update API
  URL: `admin/venues/1/reservations/1`

  Method: `PATCH`

  Request body:

  ```
    date: '31/01/2017', // optional,
    start_tact: '12:00', // optional,
    end_tact: '13:00', // optional,
    price: 10,
    amount_paid: 5,
    court_id: 4,
    coach_ids: [3,4],
    note: 'text',
    game_pass_id: 2,
    paid_in_full: false,
  ```

  * Success Response: `200` with `show` action contents

  * Error Response: `errors: { field_name: ['errors list']`

    if coach is unavailable:
      `errors: { coach: ['unavailable']`


## Copy API

  URL: `/admin/venues/1/reservations/1/copy`

  Method: `POST`

  Request body:

  ```
    reservation: {
      court_id: 1,
      start_tact: '13:00',
      end_tact: '14:00',
      date: '31/01/2017'
    }
  ```

  Success response: 201, with `show` action contents

  Error response: `errors: { field_name: ['errors list']`

## Toggle resell state
  Toggles `reselling` field

  URL: `/admin/venues/1/reservations/1/toggle_resell_state`

  Method: `PATCH`

  Request body: none

  Success response: 200, with `show` action contents

  Error response: `errors: { field_name: ['errors list']`

## Resell to user

  URL: `/admin/venues/1/reservations/1resell_to_user`

  Method: `PATCH`

  Request body:

  ```
    {
      user: USER_OBJECT // see "create" action for details on this
    }
  ```

  Success response: 200, with `show` actions contents

  Error response: `errors: { field_name: ['errors list']`

## Destroy

  URL: `/admin/venues/1/reservations/1`

  Method: `DELETE`

  Request body: none

  Success response: 200, with an array containing removed reservation ID.

## Mark Salary Paid Many API
  Marks selected reservations+coach as salary paid

  * **URL**

    /admin/venues/1/reservations/mark_salary_paid_many

  * **Method:**

    `GET`

  *  **Request Body:**

  ```
    {
      reservation_ids: [1, 2],
      coach_id: 1,
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `[1, 2]`



# Reports API

  Listed below are Reports API endpoints.<br />
  This API requires authenticated admin.

## Download Sales Report API

  Returns XLSX file with sales (reservations) for venue.<br />

  * **URL**

    /admin/reports/download_sales_report

  * **Method:**

    `GET`

  *  **Request Body:**

  ```
    {
      venue_id: 1,
      start: '01/10/2024',
      end: '31/12/2024',
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** file Sales_Report_01-10-2024_31-12-2024.xlsx

## Download Invoices Report API

  Returns XLSX file with invoices for company.<br />

  * **URL**

    /admin/reports/download_invoices_report

  * **Method:**

    `GET`

  *  **Request Body:**

  ```
    {
      start: '01/10/2024',
      end: '31/12/2024',
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** file Invoices_Report_01-10-2024_31-12-2024.xlsx

## Payment Transfers API pdf

  Returns PDF file with Stripe transfers for company.<br />

  * **URL**

    /admin/reports/payment_transfers.pdf

  * **Method:**

    `GET`

  *  **Request Body:**

  ```
    {
      start: '01/10/2024',
      end: '31/12/2024',
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** file report.pdf


# User Invoices API

  Listed below are User Invoices API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API

  Returns JSON data.<br />

  * **URL**

    /admin/users/1/invoices

  * **Method:**

    `GET`

  * **Success Response:**
      - invoices visible to the user (`is_draft` is false).

    * **Code:** 200 <br />
      **Content:**

  ```
  {
     invoices : [
        {
           company_id: 36,
           total: "100.0",
           reference_number: "43036 22547",
           pdf_url: "http://localhost:3030/companies/36/invoices/80.pdf",
           created_at: "2017-03-15T05:38:22.690Z",
           due_time: "2017-03-29T00:00:00.000+03:00",
           is_draft: false,
           updated_at: "2017-03-15T06:05:19.389Z",
           id: 80,
           owner_id: 970,
           owner_type: 'User',
           is_paid: true
        },
        ...
     ]
  }
  ```

# Reservations API

  Listed below are Reservations API endpoints.<br />
  This API requires authenticated admin and created venue.

## Future Reservations API API

  Returns JSON data.<br />
  Accepts optional parameters: `venue_id`, `user_id` <br />

  * **URL**

    /admin/future_reservations.json?user_id=1&venue_id=1

  * **Method:**

    `GET`

  * **Success Response:**
      - future reservations for the company (optionally filtered by user and venue)

    * **Code:** 200 <br />
      **Content:**

  ```
  {
     "reservations" : [
        {
           "court" : {
              "surface" : "hard_court",
              "duration_policy" : "one_hour",
              "created_at" : "2016-11-09T14:34:13.422Z",
              "id" : 93,
              "sport_name" : "tennis",
              "court_name" : "Indoor 2",
              "custom_name" : null,
              "active" : true,
              "private" : false,
              "indoor" : true,
              "start_time_policy" : "any_start_time",
              "index" : 2,
              "venue_id" : 14,
              "updated_at" : "2016-11-09T15:03:28.003Z",
              "payment_skippable" : false,
              "court_description" : "",
              "sport" : "Tennis"
           },
           "user_type" : "User",
           "resold" : false,
           "amount_paid" : 0,
           "inactive" : false,
           "date" : "03/04/2017",
           "paid_in_full" : false,
           "has_membership" : false,
           "end_time" : "2017-04-03T12:30:00.000-07:00",
           "refunded" : false,
           "created_at" : "2017-04-03T02:36:58.877Z",
           "future" : false,
           "payment_type" : "unpaid",
           "reselling" : false,
           "is_paid" : false,
           "id" : 6806,
           "court_id" : 93,
           "start_tact" : "09:30",
           "start_time" : "2017-04-03T09:30:00.000-07:00",
           "billing_phase" : "not_billed",
           "total" : null,
           "charge_id" : null,
           "note" : null,
           "updated_at" : "2017-04-03T02:36:58.877Z",
           "price" : "60.0",
           "user_id" : 975,
           "booking_type" : "online",
           "refundable" : false,
           "end_tact" : "12:30",
           "initial_membership_id" : null
        },
        ...
     ]
  }
  ```


# Groups API
  Listed below are Groups API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns groups JSON

  * **URL**

    /admin/venues/:venue_id/groups

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      groups:[
        {
          # same as Show API response
        }
      ],
      pagination: { ... }
    }
  ```

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Show API
  Returns group JSON

  * **URL**

    /admin/venues/:venue_id/groups/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      id: 14,
      name: "Falcons",
      max_participants: 4,
      priced_duration: "session",
      cancellation_policy: "participation",
      classification_id: 1,
      description: '...',
      participation_price: "13.0",
      skill_levels: [4.5, 5.5],
      seasons: [
        {
          id: 5,
          start_date: "2017-05-23",
          end_date: "2017-08-23",
          current: true,
          created_at: "2017-05-23T10:42:04.205Z",
          updated_at: "2017-05-23T10:42:04.205Z"
        }
      ],
      owner_id: 19, # will be NULL if Admin
      owner: { first_name... }, # User or Admin json
      coach_ids: [1,2],
      coaches: [{ first_name... }, ...], # Coaches json
      created_at: "2017-05-23T10:27:04.242Z",
      updated_at: "2017-05-23T10:27:04.242Z",
    }
  ```

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Create API
  Creates group and returns group JSON

  * **URL**

    /admin/venues/:venue_id/groups

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      group: {
        name: "Falcons",
        max_participants: 4,
        priced_duration: "session",
        cancellation_policy: "participation",
        classification_id: 1,
        description: '...',
        participation_price: "13.0",
        skill_levels: [4.5, 5.5],
        seasons: [
          {
            start_date: "25/05/2017",
            end_date: "25/05/2017",
            current: true
          }
        ],
        owner_id: 19, # NULL if Admin
        coach_ids: [1], # optional
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { classification: ["can't be blank"], seasons: ["Start Date overlaps with other seasons"] } }`


## Update API
  Updates group and returns group JSON

  * **URL**

    /admin/venues/:venue_id/groups/:id

  * **Method:**

    `PATCH`

  *  **Request Body:**

  ```
    {
      group: {
        name: "Falcons",
        max_participants: 4,
        priced_duration: "session",
        cancellation_policy: "participation",
        classification_id: 1,
        description: '...',
        participation_price: "13.0",
        skill_levels: [4.5, 5.5],
        seasons: [
          {
            id: 5,
            start_date: "25/05/2017",
            end_date: "25/05/2017",
            current: false,
            _destroy: true
          },
          {
            start_date: "25/05/2017",
            end_date: "25/05/2017",
            current: true
          }
        ],
        owner_id: 19, # NULL if Admin
        coach_ids: [1], # optional
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { classification: ["can't be blank"], seasons: ["Start Date overlaps with other seasons"] } }`


## Delete API
  Deletes group

  * **URL**

    /admin/venues/:venue_id/groups/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1]`

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Delete Many API
  Deletes groups

  * **URL**

    /admin/venues/:venue_id/groups/destroy_many

  * **Method:**

    `DELETE`

  *  **Request Body**: `{ group_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Duplicate Many API
  Duplicates many groups with seasons

  * **URL**

    /admin/venues/:venue_id/groups/duplicate_many

  * **Method:**

    `POST`

  *  **Request Body**: `{ group_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Select options API
  Returns groups select options for venue.

  * **URL**

    /admin/venues/:venue_id/groups/select_options

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      [{ value: 16, label: 'Falcons(John Doe)' }]
    }
  ```



# Group Classifications API
  Listed below are Group Classifications API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns group classifications JSON

  * **URL**

    /admin/venues/:venue_id/group_classifications

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      group_classifications:[
        {
          # same as Show API response
        }
      ],
      pagination: { ... }
    }
  ```

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Show API
  Returns group classification JSON

  * **URL**

    /admin/venues/:venue_id/group_classifications/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      id: 14,
      name: "Underaged",
      deletable: true, # can not be deleted if primary to some group
      created_at: "2017-05-23T10:27:04.242Z",
      updated_at: "2017-05-23T10:27:04.242Z",
    }
  ```

  * **Error Response:**
    If venue or group classification not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

## Create API
  Creates group classification and returns group classification JSON

  * **URL**

    /admin/venues/:venue_id/group_classifications

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      group_classification: {
        name: "New aged",
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { name: ["can't be blank"] } }`


## Update API
  Updates group classification and returns group classification JSON

  * **URL**

    /admin/venues/:venue_id/group_classifications/:id

  * **Method:**

    `PATCH`

  *  **Request Body:**

  ```
    {
      group_classification: {
        name: "New aged",
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue or group classification not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { name: ["can't be blank"] } }`


## Delete API
  Deletes group classification

  * **URL**

    /admin/venues/:venue_id/group_classifications/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1]`

  * **Error Response:**
    If venue or group classification not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Delete Many API
  Deletes group classifications

  * **URL**

    /admin/venues/:venue_id/group_classifications/destroy_many

  * **Method:**

    `DELETE`

  *  **Request Body**: `{ group_classification_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`



# Group Custom Billers API
  Listed below are Group Custom Billers API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns group custom billers JSON

  * **URL**

    /admin/group_custom_billers

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      group_custom_billers:[
        {
          # same as Show API response
        }
      ],
      pagination: { ... }
    }
  ```


## Show API
  Returns group custom biller JSON

  * **URL**

    /admin/group_custom_billers/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      id: 8,
      group_ids: [8, 9],
      country_id: 1,
      company_legal_name: "Test Company",
      company_business_type: "OY",
      company_tax_id: "FI2381233",
      bank_name: "best bank",
      company_iban: "GR16 0110 1250 0000 0001 2300 695",
      company_bic: "34536758345633",
      company_street_address: "Mannerheimintie 5",
      company_zip: "00100",
      company_city: "Helsinki",
      company_phone: "+3585094849438",
      company_website: "www.testcompany.com",
      tax_rate: '0.1',
      invoice_sender_email: "test@test.test"
      created_at: "2017-05-23T17:02:00.187Z",
      updated_at: "2017-05-23T17:02:00.187Z",
    }
  ```

  * **Error Response:**
    If group custom biller not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Create API
  Creates group custom biller and returns group custom biller JSON

  * **URL**

    /admin/group_custom_billers

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      group_custom_biller: {
        group_ids: [8, 9],
        country_id: 1,
        company_legal_name: "Test Company",
        company_business_type: "OY",
        company_tax_id: "FI2381233",
        bank_name: "best bank",
        company_iban: "GR16 0110 1250 0000 0001 2300 695",
        company_bic: "34536758345633",
        company_street_address: "Mannerheimintie 5",
        company_zip: "00100",
        company_city: "Helsinki",
        company_phone: "+3585094849438",
        company_website: "www.testcompany.com",
        invoice_sender_email: "test@test.test",
        tax_rate: 0.1
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { name: ["can't be blank"] } }`


## Update API
  Updates group custom biller and returns group custom biller JSON

  * **URL**

    /admin/group_custom_billers/:id

  * **Method:**

    `PATCH`

  *  **Request Body:**

  ```
    {
      group_custom_biller: {
        group_ids: [8, 9],
        country_id: 1,
        company_legal_name: "Test Company",
        company_business_type: "OY",
        company_tax_id: "FI2381233",
        bank_name: "best bank",
        company_iban: "GR16 0110 1250 0000 0001 2300 695",
        company_bic: "34536758345633",
        company_street_address: "Mannerheimintie 5",
        company_zip: "00100",
        company_city: "Helsinki",
        company_phone: "+3585094849438",
        company_website: "www.testcompany.com",
        invoice_sender_email: "test@test.test"
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue or group custom biller not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { name: ["can't be blank"] } }`


## Delete API
  Deletes group custom biller

  * **URL**

    /admin/group_custom_billers/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1]`

  * **Error Response:**
    If venue or group custom biller not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Delete Many API
  Deletes group custom billers

  * **URL**

    /admin/group_custom_billers/destroy_many

  * **Method:**

    `DELETE`

  *  **Request Body**: `{ group_custom_biller_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Groups options API
  Returns groups without any biller(available for select) options for the group custom biller create/edit form.<br />
  If `group_custom_biller_id` was sent(from edit form) it will include groups already connected to this biller(for selected options).

  * **URL**

    /admin/group_custom_billers/options

  * **Method:**

    `GET`

  *  **Request Body:**

  ```
    {
      group_custom_biller_id: 1 # optional
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      [{ value: 16, label: 'Falcons(John Doe)' }]
    }
  ```



# Group Subscriptions API
  Listed below are Group Subscriptions API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns group subscriptions(seasonal membership payments) JSON

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/subscriptions

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      subscriptions: [
        {
          id: 4,
          is_paid: false,
          billing_phase: "not_billed",
          start_date: "2017-05-24",
          end_date: "2017-08-24",
          current: true,
          price: 300.0,
          amount_paid: 100.0,
          group_id: 3,
          payable: true,
          cancelable: true,
          user: { first_name... # user json },
          created_at: "2017-05-24T07:05:05.607Z",
          updated_at: "2017-05-24T07:05:05.607Z",
        }
      ],
      pagination: { ... }
    }
  ```

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Delete API
  Cancels group subscription

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/subscriptions/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1]`

  * **Error Response:**
    If venue or group or subscription not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If can't cancel:
    * **Code:** 422 <br />


## Delete Many API
  Cancels group subscriptions

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/subscriptions/destroy_many

  * **Method:**

    `DELETE`

  *  **Request Body**: `{ subscription_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Mark Paid Many API
  Marks paid group subscriptions.
  If `amount` was supplied it will partially pay subscriptions with this amount, leaving them unpaid.

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/subscriptions/mark_paid_many

  * **Method:**

    `PATCH`

  *  **Request Body**: `{ subscription_ids: [1, 2], amount: 3.4 }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Mark Unpaid Many API
  Marks group subscriptions as unpaid

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/subscriptions/mark_unpaid_many

  * **Method:**

    `PATCH`

  *  **Request Body**: `{ subscription_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`



# Group Reservations API
  Listed below are Group Reservations API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns group reservations JSON

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/reservations

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      reservations: [
        { #base reservations json(look up Reservations API) }
      ],
      pagination: { ... }
    }
  ```

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`



# Group Members API
  Listed below are Group Members API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns group members JSON

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/members

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      members:[
        {
          # same as Show API response
        }
      ],
      pagination: { ... }
    }
  ```

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Show API
  Returns group member JSON

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/members/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      id: 14,
      group_id: 3,
      user: { first_name... # user JSON }
      created_at: "2017-05-23T10:27:04.242Z",
      updated_at: "2017-05-23T10:27:04.242Z",
    }
  ```

  * **Error Response:**
    If venue or group or member not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Create API
  Creates group member and returns group member JSON

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/members

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      member: {
        user_id: 1,
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { user: ["can't be blank"] } }`


## Delete API
  Deletes group member

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/members/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1]`

  * **Error Response:**
    If venue or group or member not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Delete Many API
  Deletes group members

  * **URL**

    /admin/venues/:venue_id/groups/:group_id/members/destroy_many

  * **Method:**

    `DELETE`

  *  **Request Body**: `{ member_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue or group not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`



# Participations API
  Listed below are Participations API endpoints.<br />
  This API requires authenticated admin.

## Index API
  Returns participations JSON

  * **URL**

    /admin/venues/:venue_id/reservations/:reservation_id/participations

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      participations:[
        {
          # same as Show API response
        }
      ],
      pagination: { ... }
    }
  ```

  * **Error Response:**
    If venue or reservation not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Show API
  Returns participation JSON

  * **URL**

    /admin/venues/:venue_id/reservations/:reservation_id/participations/:id

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**:

  ```
    {
      id: 14,
      is_paid: false,
      billing_phase: 'not_billed',
      price: 13.0,
      user: { first_name... # user JSON }
      created_at: "2017-05-23T10:27:04.242Z",
      updated_at: "2017-05-23T10:27:04.242Z",
    }
  ```

  * **Error Response:**
    If venue, reservation or participation not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Create API
  Creates participation and returns participation JSON

  * **URL**

    /admin/venues/:venue_id/reservations/:reservation_id/participations

  * **Method:**

    `POST`

  *  **Request Body:**

  ```
    {
      participation: {
        user_id: 1,
        price: 11.5,
      }
    }
  ```

  * **Success Response:**

    * **Code:** 201 <br />
      **Content**:

  ```
    {
      # same as Show API response
    }
  ```

  * **Error Response:**
    If venue or reservation not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`

    If invalid params:
    * **Code:** 422 <br />
      **Content:** `{ errors: { user: ["can't be blank"] } }`


## Delete API
  Deletes group classification

  * **URL**

    /admin/venues/:venue_id/reservations/:reservation_id/participations/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1]`

  * **Error Response:**
    If venue, reservation or participation not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Delete Many API
  Deletes participations

  * **URL**

    /admin/venues/:venue_id/reservations/:reservation_id/participations/destroy_many

  * **Method:**

    `DELETE`

  *  **Request Body**: `{ participation_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue or reservation not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


## Mark Paid Many API
  Marks participations as paid

  * **URL**

    /admin/venues/:venue_id/reservations/:reservation_id/participations/mark_paid_many

  * **Method:**

    `PATCH`

  *  **Request Body**: `{ participation_ids: [1, 2] }`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content**: `[1, 2]`

  * **Error Response:**
    If venue or reservation not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Record not found."] }`


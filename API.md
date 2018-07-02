# Playven API Documentation

  This page includes our API documentation and styleguide on how to write your API documentation.

  Please pay attention to how you write it as it will be vital for others working to clearly understand how it works.
  Especially in cases where the other person might be a frontend developer with no knowledge of our backend.

## Table of Contents
  1. [Style Guide](#style-guide)
  1. [Signing Requests](#signing-requests)
  1. [I18n](#i18n)
  1. [Authentication](#authentication)
      1. [Login API](#login-api)
      1. [Register API](#register-api)
      1. [Social sign in API](#social-sign-in-api)
      1. [Update Profile API](#update-profile-api)
      1. [Reset Password API](#reset-password-api)
      1. [Change password after reset API](#change-password-after-reset-api)
      1. [Confirm Account API](#confirm-account-api)
      1. [Email Check API](#email-check-api)
      1. [Delete User API](#delete-user-api)
  1. [Invoices](#invoices)
      1. [Index API](#index-api)
      1. [Show API](#show-api)
      1. [Pay API](#pay-api)
  1. [Users](#users)
      1. [Change Location API](#change-location-api)
      1. [Upload Photo](#upload-photo)
      1. [Update Country API](#update-country-api)
      1. [Toggle Venue Email Subscription API](#toggle-venue-email-subscription-api)
      1. [User Venues API](#user-venues-api)
      1. [Groups API](#groups-api)
        1. [Index API](#groups-index-api)
        1. [Show API](#groups-show-api)
      1. [Participations API](#participations-api)
        1. [Index API](#participations-index-api)
        1. [Show API](#participations-show-api)
        1. [Cancel API](#participations-cancel-api)
      1. [Participation Credits API](#participation-credits-api)
        1. [Index API](#participation-credits-index-api)
        1. [Show API](#participation-credits-show-api)
        1. [Use API](#participation-credits-use-api)
  1. [Devices](#devices)
      1. [Create API](#create-api)
      1. [Destroy API](#destroy-api)
  1. [Customers](#customers)
      1. [Index API](#index-api-1)
      1. [Show API](#show-api-1)
      1. [Create API](#create-api-1)
      1. [Update API](#update-api)
      1. [Delete API](#delete-api)
  1. [Game Passes(user)](#game-passesuser)
      1. [Available API](#available-api)
      1. [User Game Passes API](#user-game-passes-api)
  1. [Reservations(user)](#reservationsuser)
      1. [Create API](#create-api-2)
      1. [Payment API](#payment-api)
  1. [Venues API](#venues-api)
      1. [Make Favourite](#make-favourite)
      1. [Unfavourite](#unfavourite)
      1. [Favourites](#favourites)
  1. [Search API](#search-api)
      1. [Venues](#venues)
      1. [Courts](#courts)
      1. [Terms](#terms)
  1. [Reviews](#reviews)
      1. [Index API](#index-api-2)
      1. [Create API](#create-api-3)
      1. [Update API](#update-api-1)
      1. [Delete API](#delete-api-1)


# Style Guide

  When creating API Documentation for your API Endpoint it should include the following things:

  * URL for the Endpoint
  * Method of Endpoint (POST/PUT/GET/DELETE)/PATCH)
  * Request Body
  * Success Response
  * Error Response including status code and content and causes for these

  Abiding these simple rules will keep our API Documentation clean and easy to use for everyone.

  Yay!


# Signing Requests

  To make sure our API is used by authorized apps we add a `signature` header to every request.
  Signature is an md5 function of request path (w/o query string) plus secret key.
  For example, request path of this uri: `http://domain.www.address.com/super/path/?a=1&b=2`
  is `/super/path/`

  So, for example, if path is `/path` and secret key is `123` then signature should be
  ```
  md5(/path/123)
  ```

  Along with `signature` `app-name` header must be supplied. You need to request this name / key pair from the team.


# I18n

  Just include `locale` header with each request and get response with desired locale!
  Supported values: 'en' and 'fi'


# Authentication

  Listed below are Authentication related API endpoints

## Login API
  Returns json data.

  * **URL**

    /api/authenticate?email={email_ID}&password={UserPassword}

  * **Method:**

    `POST`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ auth_token: "ENCODED_AUTH_TOKEN" }`

  * **Error Response:**

    If username or password are incorrect:

    * **Code:** 403 UNAUTHORIZED <br />
      **Content:** `{ error : 'Invalid username or password' }`

    OR

    If user is not confirmed and password is blank:

    * **Code:** 422 <br />
      **Content:** `{ error: 'unconfirmed_account', message: 'User is already created but not confirmed' }`

## Register API
  Returns json data.

  * **URL**

    /api/users

  * **Method:**

    `POST`

  * **Request Body**

  ```
  {
    "user": {
      "email": "allama.iqbal@gmail.com",
      "password": "SECRET_KEY",
      "password_confirmation": "SECRET_KEY",
      "first_name": "Allama",
      "last_name": "Iqbal",
      "phone_number": "00923366521421",
      "street_address": "15",
      "zipcode": 56000,
      "city": "Islamabad"
    }
  }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ auth_token: "ENCODED_AUTH_TOKEN" }`

  * **Error Response:**

    If user is not confirmed and password is blank:

    * **Code:** 422 <br />
      **Content:** `{ error: 'unconfirmed_account', message: 'User is already created but not confirmed' }`

    OR

    If user is not confirmed and password is present:

    * **Code:** 422 <br />
      **Content:** `{ error: 'already_exists', message: 'Email already exists' }`

## Social sign in API
  Helps you to sign in through social. You need to obtain `code` + `status` parameters
  from the social network. For instance, open /auth/facebook, authenticate and when social
  will redirect you look at the query string - those are your parameters! Send them here and receive a response
  just like from regular sign in or sign up action.

  * **URL**

    /auth/facebook/callback

  * **Method:**
    `POST`

  * **Request Body**

    Send everything you have in query string from the social.
    ```
    {
      "status": "...",
      "code": "..."
    }
    ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ auth_token: "ENCODED_AUTH_TOKEN" }`

  * **Error Response:**

    * **Code:** 422 <br />
      **Content:** `{ error: 'social_network_error', message: 'Social network error', email: 'user@memail.com', id: 1 }`

## Update Profile API
  Returns json data.

  * **URL**

    /api/users/{user_id}

  * **Method:**

    `PUT`

  * **Request Body**

    ```
    { "user":
      {"email": "test@gmail.com",
      "first_name": "Test1",
      "last_name": "Test1",
      "phone_number": "00923366521421",
      "street_address": "15",
      "zipcode": 56000,
      "city": "Lahore" }
    }
    ```

  * **Success Response:**

    if password and current_password are provided in the request body:

    * **Code:** 200 <br />
      **Content:** `{ message: "Password updated successfully", auth_token: "..." }`

    OR

    if password and current_password are not provided in the request body:

    * **Code:** 200 <br />
      **Content:** `{ message: "User profile updated successfully", auth_token: "..." }`

    Please note that you need to use the new auth_token.

  * **Error Response:**

    if `current_password` is incorrect:

    * **Code:** 422 <br />
      **Content:** `{ error : "Current password is not valid" }`

    if `password` length is short:

    * **Code:** 422 <br />
      **Content:** `{ error : "Password is too short" }`

    OR

    * **Code:** 401 UNAUTHORIZED <br />
      **Content:** `{ error : "You are not currently logged in." }`

## Reset Password API

  * **URL**

    /password?user[email]={email_ID}

  * **Method:**

    `POST`

  * **Success Response:**

    * **Code:** 201 <br />
      **Content:** `{ }`

  * **Error Response:**

    * **Code:** 404 <br />
      **Content:** `{"errors":{"email":["not found"]}}`

## Change password after reset API
  Changes password after reset

  * **URL**
    /password

  * **Method:**
    `PUT or PATCH`

  * **Body:**
    `user: { password: '...', password_confirmation: '...', reset_password_token: '...' }`

  * **Success Response**

    **Code:** 200
    **Content:** {"auth_token": "..."}

  * **Error Response:**

    * **Code:** 422 <br />
      **Content:** `{"errors":{"reset_password_token":["is not valid"]}}`

## Confirm Account API
  Returns json data.

  * **URL**

    /api/users/confirm_account

  * **Method:**

    `POST`

  * **Request Body**

  ```
  {
    "user": {
      "email": "test@test.com"
    }
  }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ message: "Confirmation email sent successfully" }`

  * **Error Response:**

    * **Code:** 422 <br />
      **Content:** `{ error : "Email parameter is required" }`

    OR

    * **Code:** 422 <br />
      **Content:** `{ error : "Confirmation email could not be sent" }`

## Email Check API

  End point for Mobile Devices in Login to check if there is an user with given email address. Returns a json message.

  * **URL**

  ```
    /api/users/email_check
  ```

  * **Method:**

  `GET`

  * **Request Body**
  ```
    {
      "email": "check@email.com"
    }
  ```

  * **Success Response**

    * **Code** 200
      **Content** `{ message: "Account found with given email" }`

  * **Error Response**

  With an invalid email param or no user account found

    * **Code** 422
    * **Content** `{ message: "No account found with given email" }`

  With no email given

    * **Code** 422
    * **Content** `{ message: "Email parameter is required" }`

## Delete User API

  End point to delete current user account

  * **URL**

  ```
    /api/users/{user_id}
  ```

  * **Method**

  `DELETE`

  * **Success Response**

    * **Code 200**
    * **Content** `{ message: "User is deleted successfully" }`

  * **Error Response**

  With user due payments

    * **Code 422**
    * **Content** `{ message: "User with due payment cannot be deleted" }`


# Invoices

  Listed below are user invoices related API endpoints.<br/>
  This API requires authenticated user.

## Index API
  Returns json data.<br />
  Accepts no parameters.<br />

  * **URL**

    /api/invoices

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      invoices: [
        {
          id:                                   3,
          total:                                22,
          isPaid:                               true,
          referenceNumber:                      '22-34923',
          billingTime:                          '23/2/1992',
          dueTime:                              '23/2/1993',
          url:                                  'http://domain.com/invoices/3',
          components: {
            id:                                 3,
            price:                              22,
            ... see reservation index response
          },
          customComponents: {
            id:                                 3,
            price:                              22,
            name:                               'name'
            is_billed:                          false,
            is_paid:                            false
          },
          gamepassComponents: {
            id:                                 3,
            price:                              22,
            is_billed:                          false,
            is_paid:                            false
          },
          participationComponents: {
            id:                                 3,
            price:                              22,
            ... see reservation index response
          },
          groupSubscriptionComponents: {
            id:                                 3,
            price:                              22,
            is_billed:                          false,
            is_paid:                            false,
            groupName:                          'falcons',
            startDate:                          '24/03/2017',
            endDate:                            '23/06/2017'
          }
        },
        ...
      ]
    }
  ```

## Show API
  Returns pdf.

  * **URL**

    /api/invoices/3.pdf

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** pdf file of invoice <br />

  * **Error Response:**

    If invoice not found:

    * **Code:** 404 <br />
      **Content:** `{ errors: ["Can not find invoice with id 3"] }`

## Pay API
  Returns json data.

  * **URL**

    /api/invoices/3/pay.pdf

  * **Method:**

    `POST`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** same as Invoices index API <br />

  * **Error Response:**

    If payment fails with an exception:

    * **Code:** 400 <br />
      **Content:** `{ "thrown exception" }`


# Users

  Listed below are Users API endpoints.<br />
  This API requires authenticated user.

## Change Location API
  returns success message.
  updates user stored location as current city
  Can also include [optional] longitude and latitude

  * **URL**

    /api/users/:id/change_location

  * **Method:**

    `POST`

  * **Request Body**

  ```
    {
      "location": {
        "longitude":           "1023.0",
        "latitude":            "1000.0"
        "current_city":        "Cairo"
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      { msg: 'success message'}
  ```
  * **Error Response:**
    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["... ", ...] }`

## Upload Photo
  uploads photo and changes current profile picture of user.

  * **URL**

    /api/users/upload_photo

  * **Method:**

    `POST`

  * **Request Body**

  ```
    {
      "photo": {
        -- file contents (Base64 encoded) --
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ auth_token: "ENCODED_AUTH_TOKEN" }`

## Update Country API
  Updates user stored country (country to search for venues).
  Returns empty response.

  * **URL**

    /api/user/countries/:country_id (country id can be a iso_2 country code, like "FI", or id
    from Country table)

  * **Method:**

    `POST`

  * **Request Body**

  ```
    { }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  * **Error Response:**
    If update validation errors:
    * **Code:** 422 <br />

## Toggle Venue Email Subscription API
  Toggles email subscription for a specific venue

  * **URL**
    /api/users/:user_id/subscriptions/toggle_email_subscription

  * **Method**
    `PATCH`

  * **Request Body**

    ```
      {
        venue_id: 1
      }
    ```

  * **Success Response:**

    ```
      {
        venues: [
          {
            id: 1,
            email_subscription: true,
            image_thumbnail: '...',
            image_small: '...',
            venue_name: '...'
          },
          ...
        ]
      }
    ```

## User Venues API
  Lists all venues the user has joined

  * **URL**
    /api/users/:user_id/subscriptions/venues

  * **Method**
    `GET`

  * **Success Response**

    ```
      {
        venues: [
          {
            id: 1,
            email_subscription: true,
            image_thumbnail: '...',
            image_small: '...',
            venue_name: '...'
          },
          ...
        ]
      }
    ```


## Groups API
  Listed below are User Groups API endpoints.
  This API requires authenticated user.

### Index API
  Returns groups list JSON

  * **URL**
    /api/groups

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      groups: [
        {
          id: 1,
          classification_id: 3
          name: 'falcons'
          description: '...'
          participation_price: 400.0,
          max_participants: 333,
          priced_duration: 'season',
          cancellation_policy: 'participation', # or refund, none
          skill_levels: [2.5, 3.0, 3.5, 4.0, 4.5, 5.0],
          url: '/api/users/1/groups/1'
          seasons: [
            {
              id: 2,
              start_date: 24/03/2017',
              end_date: 24/06/2017',
              current: true,
            },
            ...
          ],
          owner_id: 19, # will be NULL if Admin
          owner: { first_name... }, # User or Admin json
          coach_ids: [1,2],
          coaches: [{ first_name... }, ...], # Coaches json
          created_at: "2017-05-23T10:27:04.242Z",
          updated_at: "2017-05-23T10:27:04.242Z",
        },
        ...
      ]
    }
  ```


### Show API
  Returns group JSON with members and resedrvations data

  * **URL**

    /api/groups/1

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      id: 1,
      classification_id: 3
      name: 'falcons'
      description: '...'
      participation_price: 400.0,
      max_participants: 333,
      priced_duration: 'season',
      cancellation_policy: 'participation', # or refund, none
      skill_levels: [2.5, 3.0, 3.5, 4.0, 4.5, 5.0],
      url: '/api/users/1/groups/1'
      seasons: [
        {
          id: 2,
          start_date: 24/03/2017',
          end_date: 24/06/2017',
          current: true,
        },
        ...
      ],
      owner_id: 19, # will be NULL if Admin
      owner: { first_name... }, # User or Admin json
      coach_ids: [1,2],
      coaches: [{ first_name... }, ...], # Coaches json
      created_at: "2017-05-23T10:27:04.242Z",
      updated_at: "2017-05-23T10:27:04.242Z",
      members: [
        {
          id 1,
          first_name 'John',
          last_name 'Doe',
          email 'user@email',
          phone_number '123456789',
          city 'Ontario',
        },
        ...
      ],
      reservations: [
        { # see reservations index api }
      ]
    }
  ```


## Participations API
  Listed below are User Participations API endpoints.<br />
  This API requires authenticated user.

### Index API
  Returns participations list JSON

  * **URL**

    /api/participations

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      participations: [
        id: 1,
        is_paid: false,
        billing_phase: 'not_billed',
        price: 13.0,
        reservation: { # see user reservations index api }
        group: { # see user groups index api }
      ]
    }
  ```


### Show API
  Returns participation with related reservation and group JSON

  * **URL**

    /api/participations/1

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      id: 1,
      reservation: { # see user reservations index api }
      group: { # see user groups index api }
    }
  ```


### Cancel API
  Returns empty response

  * **URL**

    /api/participations/1/cancel

  * **Method:**

    `PATCH`

  * **Success Response:**

    * **Code:** 200 <br />

  * **Error Response:**

    * **Code:** 422 <br />



## Participation Credits API
  Listed below are User Participation Credits API endpoints.<br />
  This API requires authenticated user.

### Index API

  * **URL**

    /api/participation_credits

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      participation_credits:  [
        {
          id: 1,
          company: {
            id: 1
            name: 'Martinmäen Tenniskeskus Oy'
          },
          group_classification: {
            id: 1,
            name: '25-35 years old',
          }
        },
        ...
      ]
    }
  ```


### Show API

  * **URL**

    /api/participation_credits/1

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    {
      id: 1,
      company: {
        id: 1
        name: 'Martinmäen Tenniskeskus Oy'
      },
      group_classification: {
        id: 1,
        name: '25-35 years old',
      },
      applicable_reservations: [
        {
          ..., # see user reservations index api
          group: { # see user groups index api }
        },
        ...
      ]
    }
  ```


### Use API
  Returns empty response

  * **URL**

    /api/participation_credits/1/use

  * **Method:**

    `PATCH`

  *  **Request Body**

  ```
    { reservation_id: 1 }
  ```

  * **Success Response:**

    * **Code:** 200 <br />

  * **Error Response:**

    * **Code:** 422 <br />



# Devices

  Listed below are Devices CRUD API endpoints.<br />
  This API requires authenticated user.

## Create API
  Returns empty response.
  creates a new device with token for an authenticated user.

  * **URL**

    /api/devices

  * **Method:**

    `POST`

  * **Request Body**

  ```
    {
      "device": {
        "token":           'device token',
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />

  * **Error Response:**
    If no token is provided:
    * **Code:** 400 <br />

## Destroy API
  Returns empty response.
  Destroys a device if the proper token is included in the request headers
  under device_token.

  * **URL**

    /api/devices/destroy

  * **Method:**

    `POST`

  * **Request Headers**

  ```
    { "device_token": "device token" }
  ```
  * **Request Body**

  ```
    { }
  ```

  * **Success Response:**

    * **Code:** 200 <br />


# Customers

  Listed below are Customers CRUD API endpoints.<br />
  This API requires authenticated admin and created venue.

## Index API

  Returns json data.<br />
  Accepts optional parameters: `search, page, per_page`<br />
  `page` defaults to `1`<br />
  `per_page` defaults to `10`<br />
  `seartch` defaults to `''`<br />

  * **URL**

    /api/customers?search={query}&page=2&per_page=10

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        customers: [
          {
            id:                   3,
            first_name:           'name',
            last_name:            'lastname',
            email:                'example@mail.test',
            phone_number:         '1123456789',
            city:                 'Boston',
            street_address:       'Some address 4',
            zipcode:              '12345',
            outstanding_balance:  13.3,
            reservations_done:    25,
            last_reservation:     '25/10/2016',
            lifetime_value:       276.4,
          },
          ...
        ]
      }
  ```

  * **Error Response:**

    If venue not created:

    * **Code:** 422 <br />
      **Content:** `{ errors: ["Company doesn't have any venue yet"] }`

## Show API
  Returns json data.

  * **URL**

    /api/customers/3

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        id:                   3,
        first_name:           'name',
        last_name:            'lastname',
        email:                'example@mail.test',
        phone_number:         '1123456789',
        city:                 'Boston',
        street_address:       'Some address 4',
        zipcode:              '12345',
        outstanding_balance:  13.5,
        reservations_done:    7,
        last_reservation:     '25/10/2016',
        lifetime_value:       134.1,
      }
  ```

  * **Error Response:**
    If venue not created:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Company doesn't have any venue yet"] }`

    If customer not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Customer not found"] }`

## Create API
  Returns json data.
  If user with email already exists, connects it to company and returns JSON with existing user data.

  * **URL**

    /api/customers

  * **Method:**

    `POST`

  * **Request Body**

  ```
    {
      "customer": {
        first_name:           'new user name',
        last_name:            'lastname',
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
      **Content:**

  ```
      {
        id:                   17,
        first_name:           'new user name',
        last_name:            'lastname',
        email:                'example@mail.test',
        phone_number:         '1123456789',
        city:                 'Boston',
        street_address:       'Some address 4',
        zipcode:              '12345',
        outstanding_balance:  0,
        reservations_done:    0,
        last_reservation:     '',
        lifetime_value:       0
      }
  ```

  * **Error Response:**
    If venue not created:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Company doesn't have any venue yet"] }`

    If user with email already exists:
    * **Code:** 301 <br />
      **Content:**

  ```
      {
        id:                   3,
        first_name:           'existing user name',
        last_name:            'lastname',
        email:                'existing@mail.test',
        phone_number:         '1123456789',
        city:                 'Boston',
        street_address:       'Some address 4',
        zipcode:              '12345',
        outstanding_balance:  0,
        reservations_done:    4,
        last_reservation:     '11/10/2016',
        lifetime_value:       36
      }
  ```

    If create validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["First name can't be blank", ...] }`

## Update API
  Returns json data.
  If user with email already exists, connects it to company and returns JSON with existing user data. If possible, transfers data of user with incorrect email to existing user and deletes user with incorrect email.

  * **URL**

    /api/customers/3

  * **Method:**

    `PUT`

  * **Request Body**

  ```
    {
      "customer": {
        first_name:           'new user name',
        last_name:            'lastname',
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
      **Content:** `{ errors: ["Customer not found"] }`

    If customer already confirmed:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't modify already confirmed customer"] }`

    If venue not created:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Company doesn't have any venue yet"] }`

    If user with email already exists:
    * **Code:** 301 <br />
      **Content:**

  ```
      {
        id:                   3,
        first_name:           'existing user name',
        last_name:            'lastname',
        email:                'existing@mail.test',
        phone_number:         '1123456789',
        city:                 'Boston',
        street_address:       'Some address 4',
        zipcode:              '12345',
        outstanding_balance:  0,
        reservations_done:    4,
        last_reservation:     '11/10/2016',
        lifetime_value:       36
      }
  ```

    If update validation errors:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["First name cant be blank", ...] }`

## Delete API
  Returns json data.

  * **URL**

    /api/customers/3

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **No content**

  * **Error Response:**
    If customer not found:
    * **Code:** 404 <br />
      **Content:** `{ errors: ["Customer not found"] }`

    If customer already confirmed:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't modify already confirmed customer"] }`

    If venue not created:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Company doesn't have any venue yet"] }`

    If customer related to other company:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't modify customer with relation to other companies"] }`

    If failed to delete:
    * **Code:** 422 <br />
      **Content:** `{ errors: ["Can't delete customer"] }`


# Game Passes(user)
  User related API endpoints

## Available API
  Returns json data with game passes available for user on given court at given time

  * **URL**

    /api/game_passes/available

  * **Method:**

    `GET`

  * **Request Body:**

  Time in local timezone

  ```
    {
      venue_id: 5,
      user_id: 13362, # or will search for logged in user
      court_id: 23,
      start_time: '28/12/2016 16:00',
      end_time: '28/12/2016 17:00', # or :duration
      duration: 60 # or :end_time,
      coach_ids: [1,2]
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      [
        {value: 33, label: "15/30 Summer pass", remaining_charges: 15},
        {value: 37, label: "7/10|Tennis|Indoor|11/10/2016 - 31/12/2016|15:00-18:00(mon)", remaining_charges: 7},
        ...
      ]
  ```

## User Game Passes API
  Returns json data with game passes for user

  * **URL**

    /api/users/:user_id/game_passes

  * **Method:**

    `GET`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
      {
        "game_passes": [
          {
            "id": 1,
            "total_charges": "5.0",
            "remaining_charges": "5.0",
            "active": "true",
            "price": "12.0",
            "court_sports": "Tennis",
            "court_type": "Any",
            "dates_limit": "20/02/2017 - 02/03/2017",
            "start_date": "20/02/2017",
            "end_date": "02/03/2017",
            "time_limitations": "unlimited",
            "name": "Game Pass Name",
            "venue_id": "3",
            "venue_name": "Venue Name",
            "user_id": "2",
            "coach_ids": [1,3],
            "coach_names": ["John Smit", "Jane Doe"]
          },
          ...
        ]
      }
  ```


# Reservations(user)
  User related API endpoints

## Create API

  Creates reservations for given parameters.
  Uses game pass instead of card if parameter sent and game pass is available.
  Uses per-booking durations instead of base duration, if parameter sent.
  Charges Stripe card if game pass not found or unavailable.
  Creates unpaid reservation if unable to charge card.
  Creates nothing in case of errors.

  * **URL**

    /api/reservations

  * **Method:**

    `POST`

  * **Request Body:**
      -  `bookings:` - hash stringified to json

  ```
    {
      duration: 60,                          # minutes
      pay: true,                             # will be paid only if present
      card: 'card_19JbHMI61cakPIni7b2GSWK1', # Stripe card token
      bookings: "[
        {
          start_time: '28/12/2016 16:00',    # in local timezone
          id: 23,                            # court ID
          game_pass_id: 36,                  # opt, used instead of 'card'
          duration: 90                       # opt, priority over base duration
        },
        ...
      ]"
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:** `{ message: "Reservation is successful" }`

  * **Error Response:**
    Reservations errors

    * **Code:** 422 <br />
      **Content**

  ```
      errors: {
         "Tennis 23/01/2017, 6:00 - 7:00, Outdoor 1": [
             "Start time can not be in the past",
             "Court is closed for the selected time"
         ],
         "Tennis 23/01/2017, 14:00 - 13:00, Indoor 3": [
             "End time should be greater than Start time"
         ]
      ]
  ```


## Payment API
  Pays reservation with a Stripe card or game pass.

  * **URL**

    /api/reservations/1/payment

  * **Method:**

    `POST`

  * **Request Body:**

  ```
    {
      card_token: '...',                     # Stripe card token
                                             # OR
      game_pass_id: 1,                       # game pass ID
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **No Content**

  * **Error Response:**
    Reservation or payment errors

    * **Code:** 422 <br />
      **Content:**

      When reservation error:
  ```
      errors: { "start_time" => ["can not be in the past"] }
  ```

      When card payment error:
  ```
      errors: { "payment" => ["failed to pay with selected card"] }
  ```

      When payment method error:
  ```
      errors: { "payment" => ["unknown payment method"] }
  ```


# Venues API

## Make Favourite
  Add a venue to the list of favourites for the currently logged in user.

  * **URL**

    /api/venues/3/make_favourite

  * **Method:**

    `POST`

  * **Request Body**
    EMPTY

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**
      The new list of favourite venues

  ```
    venues: [{
      id: '...'
      venue_name: '...',
      city: '...'
      phone_number: '...',
      zip: '...',
      url '...',
      image: '...',
      website: '...'
      supported_sports: [...],
      lowest_price: '...'
    }]
  }
  ```

## Unfavourite
  Remove a venue from the list of favourites for the currently logged in user.

  * **URL**

    /api/venues/3/unfavourite

  * **Method:**

    `POST`

  * **Request Body**
    EMPTY

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**
      The new list of favourite venues

  ```
    venues: [{
      id: '...'
      venue_name: '...',
      city: '...'
      phone_number: '...',
      zip: '...',
      url '...',
      image: '...',
      website: '...'
      supported_sports: [...],
      lowest_price: '...'
    }]
  }
  ```

## Favourites
  A list of favourite venues for the currently logged in user.

  * **URL**

    /api/venues/favourites

  * **Method:**

    `GET`

  * **Request Body**
    EMPTY

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**
      The list of favourite venues

  ```
    venues: [{
      id: '...'
      venue_name: '...',
      city: '...'
      phone_number: '...',
      zip: '...',
      url '...',
      image: '...',
      website: '...'
      supported_sports: [...],
      lowest_price: '...'
    }]
  }
  ```


# Search API

## Venues
  Main website search, return venues with courts

  * **URL**

    /api/search

  * **Method:**

    `GET`

  * **Request Body**
      -  `date` and `time` in venue timezone

  ```
    {
      sport_name: 'tennis',
      duration: 60,              # 30, 60 or 120
      date: '25/10/2016',
      time: '11:30',
      location: {
        city_name: 'Helsinki',   # optional sort by distance from city center
        country: 3,              # optional country id
        bounding_box: {          # optional hash, all values must present, otherwise ignored
          sw_lat: 60.3413,       # Coordinates of 2 points are defined here: South West (sw) and North East (ne)
          sw_lng: 13.3413,       # You need to specify both longitude (lng) and latitude (lat) for both points
          ne_lat: 41.4114,       # If you don't specify all of them (e.g. miss out one)
          ne_lng: 14.5242,       # Whole`bounding_box` hash would be ignored
        }
      }
      page: 1                    # pagination
      sort_by: 125,              # optional, one of distance, price, availability
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    response: [
      {
        venue: {
          id: '...',
          venue_name: '...',
          city: '...',
          image: '...',
          image_small: '...',
          average_rating: 4,
        },
        courts: [
          {
            id: 1, # just ID, see `all_courts` below
            available_times: [{
              starts_at: '...',
              ends_at: '...',
              duration: '...', # ends_at - starts_at, minutes
              price: '...'
            }],
          }
        ]
      }
    ],
    prepopulated: [
      {
        venue: {
          id: '...',
          venue_name: '...',
          city: '...'
        }
      }
    ],
    metadata: {
      # duration you passed when you did a search
      duration: 60
    }

    // 2 actions will be fired here: first `COURTS_FULFILLED` with this array, then SEARCH_COMPLETED
    // with the data above
    all_courts: [{
      id: 1,
      name: '...',
      # and all other info
    }]

  }
  ```

  Also, in case if response is an empty array one more root object will be returned:
  ```
  error: {
    error: 'nothng_found' # either nothing_found, either all_booked,
    message: 'Nothing found' # human readable error message
  }
  ```

  These error below is not a "real" error, just indicator why nothing found;
  Therefore, in case of such "error" returned code will remain 200

## Courts
  Search On Venue page API

  * **URL**

    /api/venues/:id/available_courts

  * **Method:**

    `GET`

  * **Request Body**

  ```
    {
      sport_name: 'tennis',
      date: '25/10/2016'
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
    venue: {
      id: '...'
      venue_name: '...',
      city: '...'
    },
    courts: [
      {
        id: 1, # just ID, see `all_courts` below
        available_times: [{
          starts_at: '...',
          ends_at: '...',
          duration: '...', # ends_at - starts_at, minutes
          price: '...'
        }],
      }
    ]
    },

    // 2 actions will be fired here: first `COURTS_FULFILLED` with this array, then SEARCH_COMPLETED
    // with the data above
    all_courts: [{
      id: 1,
      name: '...',
      # and all other info
    }]

  }
  ```

## Terms
  Filter by city / venue name

 * **URL**
   /api/search/filter_by_name

 * **Method**
   GET

 * **Request body**
  ```
    {
      term: 'search string'
    }
  ```

  * **Success Response:**

    * **Code:** 200<br/>
      **Content:**
  ```
    {
      cities: ['Oklahoma', 'Pukerville'],
      venues: [
        {
          id: 1,
          name: 'Venue name',
          # and other basic venue params
        }
      ]
    }
  ```


# Reviews
## Index API
  Get all reviews for a venue

  * **URL**

    /api/venues/:venue_id/reviews

  * **Method:**

    `GET`

  * **Request Body**
  ```
    {
      per_page: 10,
      page: 1
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**
      The list of venue reviews

  ```
  {
    reviews: [
      {
        id: 2,
        venue_id: 1,
        rating: 4,
        text: "test review test",
        author: {
          id: 4,
          first_name: "User4",
          last_name: "Playven",
          email: "user4@playven.com",
        },
        created_at: "2017-05-17T08:32:03.209Z",
        updated_at: "2017-05-17T08:32:03.209Z"
      },
      ...
    ],
    current_page: 1,
    total_pages: 3,
    total_reviews: 10,
    average_rating: 4.5
  }
  ```

## Create API
  Create new review for venue

  * **URL**

    /api/venues/:venue_id/reviews

  * **Method:**

    `POST`

  * **Request Body**
  ```
    {
      review: {
        rating: 4.0,
        text: "review text"
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
  {
    id: 25,
    text: "test review test",
    rating: 4,
    author_id: 4,
    venue_id: 1,
    created_at: "2017-04-03T12:26:09.314Z",
    updated_at: "2017-04-03T12:26:09.314Z"
  }
  ```

## Update API
  Update a review for venue

  * **URL**

    /api/venues/:venue_id/reviews/:id

  * **Method:**

    `PATCH`

  * **Request Body**
  ```
    {
      review: {
        rating: 4.0,
        text: "new review text"
      }
    }
  ```

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
  {
    id: 25,
    text: "new review text",
    rating: 4,
    author_id: 4,
    venue_id: 1,
    created_at: "2017-04-03T12:26:09.314Z",
    updated_at: "2017-04-03T12:26:09.314Z"
  }
  ```

## Delete API
  Delete a review for venue

  * **URL**

    /api/venues/:venue_id/reviews/:id

  * **Method:**

    `DELETE`

  * **Success Response:**

    * **Code:** 200 <br />
      **Content:**

  ```
  {
    message: "Review deleted successfully"
  }
  ```

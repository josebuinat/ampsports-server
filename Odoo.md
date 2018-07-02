# Playven API Documentation For Odoo

This page includes our API documentation for Bonware/Odoo integration.


## Table of Contents
  1. [Signing Requests](#signing-requests)
  1. [I18n](#i18n)


# Signing requests

To make sure our API is used by authorized apps we add a `signature` header to every request.
Signature is an md5 function of request body plus secret key. For example, if secret key is `123` then it could be
```
md5({"user":1}123)
```

Along with `signature` `app-name` header must be supplied. You need to request this name / key pair from the team.

# i18n

Just include `locale` header with each request and get response with desired locale!
Supported values: 'en' and 'fi'

# Courts API

This endpoint is for finding a list of courts for a specific venue.

* **URL**

```
/api/venues/:venue_id/courts
```

* **Method:**
`GET`

*  **Response Body**

```
{
  "courts": {
    "court_id": "57",
    "sport": "Tennis",
    "name": "Indoor 3"
  }
}
```


# Reservations API

This endpoint is for finding a list of reservations that start on a certain date.

* **URL**

```
/api/courts/reservations
```


## With Court Id

If a Court Id is given in the request, we return reservations that start on a given date at given court.

* **Method:**
`GET`

*  **Request Body**

```
{
  "court_id": 57,
  "date": "2017-03-02"
}
```


*  **Response Body**

```
{
  "reservations": [
    {
      "user": {
        "id": 948,
        "name": "testijesse käyttäjä",
        "first_name": "testijesse",
        "last_name": "käyttäjä"
      },
      "id": 6677,
      "booking_type": "admin",
      "court": "Aktia 1",
      "sport": "Tennis",
      "start_time": "13:30",
      "end_time": "16:30",
      "start_time_iso8601": "2017-03-02T11:30:00Z",
      "end_time_iso8601": "2017-03-02T14:30:00Z",
      "price": "€42.00",
      "amount_paid": "€0.00",
      "unpaid_amount": "€42.00",
      "payment_type": "Pay at Venue",
      "month": "March",
      "day": "02",
      "year": "2017"
    }
  ]
}
```


## Without Court Id

If there is no Court Id given, the response is the same, but we show all reservations for all courts for the venue.

*  **Request Body**

```
{
  "venue_id": 13,
  "date": "2017-03-02"
}
```


*  **Response Body**

```
{
  "reservations": [
    {
      "user": {
        "id": 948,
        "name": "testijesse käyttäjä",
        "first_name": "testijesse",
        "last_name": "käyttäjä"
      },
      "id": 6677,
      "booking_type": "admin",
      "court": "Aktia 1",
      "sport":"Tennis",
      "start_time": "13:30",
      "end_time": "16:30",
      "start_time_iso8601": "2017-03-02T11:30:00Z",
      "end_time_iso8601": "2017-03-02T14:30:00Z",
      "price": "€42.00",
      "amount_paid": "€0.00",
      "unpaid_amount": "€42.00",
      "payment_type": "Pay at Venue",
      "month": "March",
      "day": "02",
      "year": "2017"
    }
  ]
}
```

# Payment API

API endpoint to send amount paid and reference that will be added to notes.

* **Method:**
`POST`

*  **Request Body**

```
{
  "amount_paid": 13.00,
  "reservation_id": 8473
  "notes": "ODOO PAYMENT TRANSACTION: 89217381728XUHS"
}
```


* **Success Response:**

  * **Code:** 200 <br />

* **Error Response:**

  If username or password are incorrect:

  * **Code:** 422 UNAUTHORIZED <br />
    **Content:** `{ error : 'Occurred Error' }`

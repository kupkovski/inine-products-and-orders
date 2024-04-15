# This is a trivial single-file Rails application.

## Discuss how you would prevent a customer purchasing the same product twice in a live production version of this app.

To achieve this it would be important to have a mecanism of Product Stock, preventing users to buy products that was already sold out. We would need a database table to handle it, and implement database transactions on each purchase use case that will raise errors on an attempt to do such try to purchase a sold out product

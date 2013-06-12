# Excursion

Provides a pool of routes into which applications can dump their host information and routing table. Other applicans can then utilize application namespaced helper methods for redirecting, etc. between apps. Particularly useful when multiple applications are sharing a database. For example, linking from a user profile on a frontend application to a separate admin or CMS interface (hosted as a separate rails app): `my_admin_app.edit_user_url(@user)`.

### TODO: README

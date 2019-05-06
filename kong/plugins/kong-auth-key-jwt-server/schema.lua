local typedefs = require "kong.db.schema.typedefs"

return {
    name = "kong-auth-key-jwt-server",
    fields = {
        {run_on = typedefs.run_on_first},
        {protocols = typedefs.protocols_http},
        {config = {
            type = "record",
            fields = {
                {
                    header_select_token = {
                        type = "string"
                    }
                },
                {
                    url_authentication = {
                        type = "string"
                    }
                },
                {
                    method_authentication = {
                        type = "string"
                    }
                },
                {
                    body_send_token = {
                        type = "string"
                    }
                },
                {
                    param_token = {
                        type = "string"
                    }
                },
                {
                    secret_key_signature_authentication = {
                        type = "string"
                    }
                }
            }
        }}
    }
}
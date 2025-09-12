#### this is a direct copy of the lambda function from abtest backend - needs to be adapted to a module later on ####


resource "aws_lambda_function" "backend_measurements" {
  function_name = "${var.instance_name}_${var.analytics_tool == "adobe_analytics" ? "adobe" : "ga4"}_measurements"
  package_type = "Image"
  image_uri=var.image_uri
  image_config {
    command=["${var.python_package_name}/${var.measurements_entrypoint}"]
  }
  memory_size = 4096
  timeout = 15 * 60

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.

  environment {
    variables = {
      ANALYTICS_TOOL = var.analytics_tool
      BIGQUERY_PROJECT = var.bigquery_project
      DYNAMO_CONFIG_TABLE = aws_dynamodb_table.config_table.name
      DYNAMO_MEASUREMENT_TABLE = aws_dynamodb_table.measurement_table.name
      DYNAMO_DIMENSIONS_TABLE = aws_dynamodb_table.dimensions_table.name
      DYNAMO_PROPERTIES_TABLE = aws_dynamodb_table.available_properties_table.name
      DYNAMO_EXPERIMENTS_TABLE = aws_dynamodb_table.available_experiments_table.name
      DYNAMO_KPI_CONFIG_TABLE = aws_dynamodb_table.general_kpi_config_table.name
      PROPERTIES = var.properties
      EXPERIMENT_VARIABLES=var.experiment_variables
      SECRET_MANAGER_DOMAIN = var.instance_name
      BACKEND_MEASUREMENT_SPECIFIC_EXPERIMENT_LAMBDA = aws_lambda_function.backend_measurements_experiment.function_name
      APPLICATION_TYPE = var.application_type
    }
  }
  role = aws_iam_role.lambda_api_role.arn
}

resource "aws_lambda_function" "backend_measurements_experiment" {
  function_name = "${var.instance_name}_adobe_measurements_experiment"

  package_type = "Image"
  image_uri=local.image_uri
  image_config {
    command=["${var.python_package_name}/${var.measurements_specific_experiment_entrypoint}"]
  }

  memory_size = 2048
  timeout = 15 * 60

  environment {
    variables = {
      ANALYTICS_TOOL = var.analytics_tool
      BIGQUERY_PROJECT = var.bigquery_project
      DYNAMO_CONFIG_TABLE = aws_dynamodb_table.config_table.name
      PROPERTIES = var.properties
      EXPERIMENT_VARIABLES=var.experiment_variables
      DYNAMO_MEASUREMENT_TABLE = aws_dynamodb_table.measurement_table.name
      SECRET_MANAGER_DOMAIN = var.instance_name
      BACKEND_MEASUREMENT_SPECIFIC_EXPERIMENT_LAMBDA = "${var.instance_name}_adobe_measurements_experiment"
      APPLICATION_TYPE = var.application_type
    }
  }
  role = aws_iam_role.lambda_api_role.arn
}

resource "aws_lambda_function" "historical_measurements" {
  function_name = "${var.instance_name}_adobe_historical_measurements"

  memory_size = 2048
  timeout = 15 * 60

  package_type = "Image"
  image_uri=local.image_uri
  image_config {
    command=["${var.python_package_name}/${var.historical_nightly_update_entrypoint}"]
  }

  environment {
    variables = {
      ANALYTICS_TOOL = var.analytics_tool
      BIGQUERY_PROJECT = var.bigquery_project
      DYNAMO_CONFIG_TABLE = aws_dynamodb_table.config_table.name
      DYNAMO_MEASUREMENT_TABLE = aws_dynamodb_table.measurement_table.name
      SECRET_MANAGER_DOMAIN = var.instance_name
      PROPERTIES = var.properties
      EXPERIMENT_VARIABLES=var.experiment_variables
      BACKEND_MEASUREMENT_SPECIFIC_EXPERIMENT_LAMBDA = aws_lambda_function.backend_measurements_experiment.function_name
      APPLICATION_TYPE = var.application_type
    }
  }
  role = aws_iam_role.lambda_api_role.arn
}

resource "aws_lambda_function" "backend_segment_builder" {
  function_name = "${var.instance_name}_adobe_segment_builder"
  package_type = "Image"
  image_uri=local.image_uri
  image_config {
    command=["${var.python_package_name}/${var.segment_builder_entrypoint}"]
  }
  memory_size = 2048
  timeout = 15 * 60


  environment {
    variables = {
      DYNAMO_CONFIG_TABLE = aws_dynamodb_table.config_table.name
      DYNAMO_SEGMENT_TABLE = aws_dynamodb_table.segment_table.name
      DYNAMO_DIMENSIONS_TABLE = aws_dynamodb_table.dimensions_table.name
      DYNAMO_EXPERIMENTS_TABLE = aws_dynamodb_table.available_experiments_table.name
      DYNAMO_PROPERTIES_TABLE = aws_dynamodb_table.available_properties_table.name
      DYNAMO_KPI_CONFIG_TABLE = aws_dynamodb_table.general_kpi_config_table.name
      SECRET_MANAGER_DOMAIN = var.instance_name
      PROPERTIES = var.properties
      EXPERIMENT_VARIABLES=var.experiment_variables
      KPI_CONFIGURATION_ID = "main"
      SHARING_USER_IDS="200601494,200370786"
      SHARING_USER_TYPES="user,user"
      SHARING_USER_EMAILS="joaobarbosa@pvh.com,edwin@clickvalue.nl"
      APPLICATION_TYPE = var.application_type
    }
  }
  role = aws_iam_role.lambda_api_role.arn
}

resource "aws_lambda_function" "backend_api" {
  function_name = "${var.instance_name}_backend_api_wsgi"
  package_type = "Image"
  image_uri=local.image_uri
  image_config {
    command=["${var.python_package_name}/${var.wsgi_entrypoint}"]
  }
  memory_size = 1024
  timeout = 120

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.


  environment {
    variables = { 
      ANALYTICS_TOOL = var.analytics_tool
      BIGQUERY_PROJECT = var.bigquery_project
      DYNAMO_CONFIG_TABLE = aws_dynamodb_table.config_table.name
      DYNAMO_MEASUREMENT_TABLE = aws_dynamodb_table.measurement_table.name
      DYNAMO_DIMENSIONS_TABLE = aws_dynamodb_table.dimensions_table.name
      DYNAMO_EXPERIMENTS_TABLE = aws_dynamodb_table.available_experiments_table.name
      DYNAMO_SEGMENT_TABLE = aws_dynamodb_table.segment_table.name
      DYNAMO_KPI_CONFIG_TABLE = aws_dynamodb_table.general_kpi_config_table.name
      DYNAMO_PROPERTIES_TABLE = aws_dynamodb_table.available_properties_table.name
      PROPERTIES = var.properties
      EXPERIMENT_VARIABLES=var.experiment_variables
      SECRET_MANAGER_DOMAIN = var.instance_name
      BACKEND_MEASUREMENT_LAMBDA = aws_lambda_function.backend_measurements.function_name
      BACKEND_SEGMENT_BUILDER_LAMBDA = aws_lambda_function.backend_segment_builder.function_name
      KPI_CONFIGURATION_ID = "main"
      SHARING_USER_IDS="200601494,200370786"
      SHARING_USER_TYPES="user,user"
      SHARING_USER_EMAILS="joaobarbosa@pvh.com,edwin@clickvalue.nl"
      CORS_ORIGIN = var.environment == "prd" ? var.cors_origin : "*"
      APPLICATION_TYPE = var.application_type
    }
  }
  role = aws_iam_role.lambda_api_role.arn
}


#### roles and rights for users - duplicated because there is both an API role and a scheduler role

resource "aws_iam_role_policy" "sm_policy" {
  name = "${var.instance_name}_sm_access_permissions"
  role = aws_iam_role.lambda_api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_trigger_policy" {
  name = "${var.instance_name}_lambda_trigger_permissions"
  role = aws_iam_role.lambda_api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.backend_measurements.arn
      },
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.backend_segment_builder.arn
      },
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.historical_measurements.arn
      },
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.backend_measurements_experiment.arn
      },
    ]
  })
}


resource "aws_iam_role_policy" "lambda_policy_config_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_config_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.config_table.arn})
}

resource "aws_iam_role_policy" "lambda_policy_measurement_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_measurement_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.measurement_table.arn})
}

resource "aws_iam_role_policy" "lambda_policy_segment_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_segment_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.segment_table.arn})
}

resource "aws_iam_role_policy" "lambda_policy_dimensions_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_dimensions_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.dimensions_table.arn})
}

resource "aws_iam_role_policy" "lambda_policy_available_experiments_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_available_experiments_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.available_experiments_table.arn})
}


resource "aws_iam_role_policy" "lambda_policy_available_properties_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_available_properties_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.available_properties_table.arn})
}

resource "aws_iam_role_policy" "lambda_policy_kpi_config_table" {
  name = "${var.instance_name}_lambda_policy_dynamo_kpi_config_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn=aws_dynamodb_table.general_kpi_config_table.arn})
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_api_role" {
  name = "${var.instance_name}_lambda_api_role"

  assume_role_policy = file("${path.module}/assume_role_policy.json")
}


# This was needed to see logs
resource "aws_iam_role_policy_attachment" "basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_api_role.id
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_api.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.backend_api.execution_arn}/*/*"
}

resource "aws_scheduler_schedule" "historical_schedule" {
  name       = "${var.instance_name}-hist-sched"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(4 2 * * ? *)"

  target {
    arn      = aws_lambda_function.historical_measurements.arn
    role_arn = aws_iam_role.lambda_api_role.arn
  }
  depends_on = [ aws_iam_role_policy.lambda_trigger_policy ]
}

# data "aws_iam_policy_document" "sts_scheduler" {
#     statement {
#     sid = "STSassumeRole"
#     effect = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type = "Service"
#       identifiers = ["scheduler.amazonaws.com"]
#     }
#   }
# }

module "lambda_alerting" {
  source = "../aws_lambda_alert"
  name = "me-${var.instance_name}"
  lambda_name = aws_lambda_function.backend_measurements_experiment.function_name
  email_address = "alerting@cloudninedigital.nl"
  log_pattern = "%HANDLED_EXCEPTION%"
}

# module "lambda_alerting" {
#   source = "../aws_lambda_alert"
#   name = "me-${var.instance_name}"
#   lambda_name = aws_lambda_function.backend_api.function_name
#   email_address = "alerting@cloudninedigital.nl"
#   log_pattern = "%HANDLED_EXCEPTION%"
# }


###################################################################
###### TEMP ugly solution for Splitwatch plus changes seen ########
###################################################################

resource "aws_iam_role_policy" "lambda_policy_config_table_ckplus" {
  count = length(regexall(".*ckplus.*", var.instance_name)) > 0 ? 1 : 0
  name = "${var.instance_name}_ck_lambda_policy_dynamo_config_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn="arn:aws:dynamodb:eu-west-3:681241877635:table/lug_abtest_backend_ck_${terraform.workspace}_configuration_table"})
}

resource "aws_iam_role_policy" "lambda_policy_config_table_thplus" {
  count = length(regexall(".*thplus.*", var.instance_name)) > 0 ? 1 : 0
  name = "${var.instance_name}_th_lambda_policy_dynamo_config_table"
  role = aws_iam_role.lambda_api_role.id

  policy = templatefile("${path.module}/policy_dynamo.tftpl", {arn="arn:aws:dynamodb:eu-west-3:681241877635:table/lug_abtest_backend_th_${terraform.workspace}_configuration_table"})
}
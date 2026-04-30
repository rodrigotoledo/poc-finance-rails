# frozen_string_literal: true

# StrongerParameters (ActionController::Parameters extensions)
#
# We intentionally run in strict mode: invalid parameter type/casting should raise,
# so the API fails fast and clients fix their requests.
ActionController::Parameters.action_on_invalid_parameters = :raise


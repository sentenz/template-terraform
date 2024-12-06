# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

mock "tfplan/v2" {
  module {
    source = "mock/mock-tfplan-success.json"
  }
}

test {
  rules = {
    main = true
  }
}
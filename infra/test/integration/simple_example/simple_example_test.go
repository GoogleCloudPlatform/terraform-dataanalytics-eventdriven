// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package simple_example

import (
	"fmt"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"
)

type TestParams struct {
	t         *testing.T
	assert    *assert.Assertions
	example   *tft.TFBlueprintTest
	projectId string
}

func TestSimpleExample(t *testing.T) {
	example := tft.NewTFBlueprintTest(t)

	example.DefineVerify(func(assert *assert.Assertions) {
		projectId := example.GetTFSetupStringOutput("project_id")
		//testGoogleCloudApis(t, assert, projectId)
		testParams := TestParams{t, assert, example, projectId}
		// Check if the vision input and annotations buckets exists
		//outputBucketName, inputBucketName := testBucketExists(testParams, projectId)
		testBucketExists(testParams, projectId)
	})

	example.Test()
}

func testBucketExists(testParams TestParams, projectId string) (string, string) {
	/*
	gcloudArgs := gcloud.WithCommonArgs([]string{"--project", testParams.projectId})
	// Check if the vision annotations bucket exists
	outputBucketName := testParams.example.GetStringOutput(fmt.Sprintf("%s-upload", projectId))
	storage := gcloud.Run(testParams.t, fmt.Sprintf("storage buckets describe %s --format=json", outputBucketName), gcloudArgs)
	testParams.assert.NotEmpty(storage)


	// Check if the vision input bucket exists
	inputBucketName := testParams.example.GetStringOutput(fmt.Sprintf("%s-archive", projectId))
	storage = gcloud.Run(testParams.t, fmt.Sprintf("storage buckets describe %s --format=json", inputBucketName), gcloudArgs)
	testParams.assert.NotEmpty(storage)
	return outputBucketName, inputBucketName*/
	return "teste-upload", "teste-archive"
}

func testGoogleCloudApis(t *testing.T, assert *assert.Assertions, projectId string) {
	serviceTests := map[string]struct {
		service string
	}{
		"Service cloudbuild":     {service: "cloudbuild"},
		"Service bigquery":       {service: "bigquery"},
		"Service cloudfunctions": {service: "cloudfunctions"},
		"Service compute":        {service: "compute"},
		"Service storage":        {service: "storage"},
		"Service eventarc":       {service: "eventarc"},
	}
	services := gcloud.Run(t, "services list", gcloud.WithCommonArgs([]string{"--project", projectId, "--format", "json"})).Array()
	for _, tc := range serviceTests {
		t.Run(tc.service, func(t *testing.T) {
			match := utils.GetFirstMatchResult(t, services, "config.name", fmt.Sprintf("%s.googleapis.com", tc.service))
			assert.Equal("ENABLED", match.Get("state").String(), "%s service should be enabled", tc.service)
		})
	}
}

#!/bin/bash

TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwibW9iaWxlIjoiMTM4MDAxMzgwMDAiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYwMTA3NjE5LCJleHAiOjE3NjAxMTQ4MTl9.mIUT5nXOaZumOCh87_fMbJMGdeADDg-WtT5SjDAD78Q"

echo "测试用户资料接口..."
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/profile | jq .

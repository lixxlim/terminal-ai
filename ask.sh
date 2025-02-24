#!/bin/bash
content=""
userInput=""
prompt=">> "
if ! [[ -v model_arry ]]; then
    declare -a model_arry
fi
if ! [[ -v user_arry ]]; then
    declare -a user_arry
fi
#Input
if ! [[ -v model ]]; then
        model="gemini-2.0-flash"
fi
while true; do
        read -r -p "$prompt" line
        if [[ "$line" == *"#clear"* ]]; then
                unset user_arry[@]
                unset model_arry[@]
                line=""
        fi
        if [[ "$line" == *"#flash"* ]]; then
                model="gemini-2.0-flash"
                line=$(echo "$line" | sed 's/#flash//g')
        fi
        if [[ "$line" == *"#pro"* ]]; then
                model="gemini-2.0-pro-exp-02-05"
                line=$(echo "$line" | sed 's/#pro//g')
        fi
        if [[ "$line" == *"#think"* ]]; then
                model="gemini-2.0-flash-thinking-exp-01-21"
                line=$(echo "$line" | sed 's/#think//g')
        fi
        userInput="$userInput$line"$'\n'
        if [[ "$line" == *";;"* ]]; then
                userInput=$(echo "$userInput" | sed 's/;;//g')
                break
        fi
done
userInput=$( echo "$userInput" | sed 's/\"/\\\"/g' )
user_arry+=("${userInput}")

#MakeQuery
content+="{contents:"
content+="["
for i in $(seq 0 $((${#user_arry[@]} - 1))); do
        content+="{\"role\":\"user\", \"parts\":[{\"text\": \"${user_arry[i]}\"}]},"
        if [[ -v model_arry[i] ]]; then
                content+="{\"role\":\"model\", \"parts\":[{\"text\": \"${model_arry[i]}\"}]},"
        fi
done
str_len=${#content}
content="${content:0:str_len-1}]"
content+="}"

uri="https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GOOGLE_AI_API_KEY}"
response=$(curl -s -X POST \
        -H "Content-Type: application/json; charset=utf-8" \
        -H "Accept-Charset: utf-8" \
        -d "$content" \
        "$uri" 2>/tmp/curl_error.log
)

#Output
COLUMNS=$(tput cols)
echo ""
echo -e "\033[93m$(printf "%${COLUMNS}s" | tr ' ' '*')\033[0m"
if [[ -n "$response" ]]; then
        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
                echo "API 에러 발생:" >&2
                cat /tmp/curl_error.log >&2
                echo "$response" | jq .error  >&2
        elif echo "$response" | jq -e '.candidates' > /dev/null 2>&1; then
                res=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null)
                res=$(printf $q "$res")
                echo -e "\033[93m${res}\033[0m"
                res=$( echo "$res" | sed 's/\"/\\\"/g' )
                model_arry+=("$res")
        else
                echo "API 응답 구조 오류: 'candidates' 속성 없음" >&2
                echo "전체 응답 내용:" >&2
                echo "$response" | jq . >&2
        fi
else
        echo "API 요청 실패 또는 응답 없음 (curl 에러 확인)" >&2
        cat /tmp/curl_error.log >&2
fi
rm -f /tmp/curl_error.log
echo ""
echo -e "\033[93mby ${model}\033[0m"
echo -e "\033[93m$(printf "%${COLUMNS}s" | tr ' ' '*')\033[0m"
echo ""
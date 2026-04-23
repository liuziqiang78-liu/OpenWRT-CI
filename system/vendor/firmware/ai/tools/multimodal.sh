#!/system/bin/sh
# MiMo Tool: Multimodal (Image/Audio/Video Analysis)
# 用法: multimodal.sh <action> <file> [prompt]

ACTION="$1"
FILE="$2"
shift 2
PROMPT="$*"

MIMO_API="http://localhost:8080"

case "$ACTION" in
    image|analyze_image)
        if [ ! -f "$FILE" ]; then
            echo "错误: 图片不存在: $FILE"
            exit 1
        fi
        
        echo "🖼️ 分析图片: $FILE"
        echo "---"
        
        # Base64 编码图片
        IMG_B64=$(base64 "$FILE")
        
        # 发送到 MiMo 进行分析
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"分析图片内容，提供详细描述。\"},
                    {\"role\": \"user\", \"content\": [
                        {\"type\": \"text\", \"text\": \"${PROMPT:-请描述这张图片的内容}\"},
                        {\"type\": \"image_url\", \"image_url\": {\"url\": \"data:image/jpeg;base64,${IMG_B64}\"}}
                    ]}
                ],
                \"max_tokens\": 1024
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//'
        ;;
    
    ocr)
        if [ ! -f "$FILE" ]; then
            echo "错误: 图片不存在: $FILE"
            exit 1
        fi
        
        echo "📝 OCR 提取文字: $FILE"
        echo "---"
        
        IMG_B64=$(base64 "$FILE")
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"提取图片中的所有文字，保持原始格式。\"},
                    {\"role\": \"user\", \"content\": [
                        {\"type\": \"text\", \"text\": \"提取图片中的所有文字\"},
                        {\"type\": \"image_url\", \"image_url\": {\"url\": \"data:image/jpeg;base64,${IMG_B64}\"}}
                    ]}
                ],
                \"max_tokens\": 2048
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//'
        ;;
    
    audio|transcribe)
        if [ ! -f "$FILE" ]; then
            echo "错误: 音频不存在: $FILE"
            exit 1
        fi
        
        echo "🎤 转录音频: $FILE"
        echo "---"
        
        # 使用 whisper 或其他 ASR
        if command -v whisper > /dev/null 2>&1; then
            whisper "$FILE" --output_format txt --output_dir /tmp 2>/dev/null
            cat /tmp/$(basename "$FILE" | sed 's/\.[^.]*$//').txt
        else
            # 发送到 MiMo
            AUDIO_B64=$(base64 "$FILE")
            curl -s -X POST "${MIMO_API}/v1/audio/transcriptions" \
                -H "Content-Type: application/json" \
                -d "{
                    \"audio\": \"${AUDIO_B64}\",
                    \"model\": \"mimo-v2.5-pro\"
                }" 2>/dev/null
        fi
        ;;
    
    video|analyze_video)
        if [ ! -f "$FILE" ]; then
            echo "错误: 视频不存在: $FILE"
            exit 1
        fi
        
        echo "🎬 分析视频: $FILE"
        echo "---"
        
        # 提取关键帧
        FRAMES_DIR="/data/adb/mimo/tmp/frames_$(date +%s)"
        mkdir -p "$FRAMES_DIR"
        
        ffmpeg -i "$FILE" -vf "fps=1/5" "$FRAMES_DIR/frame_%04d.jpg" 2>/dev/null
        
        echo "提取了以下关键帧:"
        ls "$FRAMES_DIR"/*.jpg 2>/dev/null
        
        # 分析第一帧
        if [ -f "$FRAMES_DIR/frame_0001.jpg" ]; then
            echo ""
            echo "分析第一帧:"
            multimodal.sh image "$FRAMES_DIR/frame_0001.jpg" "描述这个视频帧的内容"
        fi
        ;;
    
    describe)
        if [ ! -f "$FILE" ]; then
            echo "错误: 文件不存在: $FILE"
            exit 1
        fi
        
        # 自动检测类型
        MIME=$(file -b --mime-type "$FILE")
        
        case "$MIME" in
            image/*)
                multimodal.sh image "$FILE" "$PROMPT"
                ;;
            audio/*)
                multimodal.sh audio "$FILE"
                ;;
            video/*)
                multimodal.sh video "$FILE"
                ;;
            *)
                echo "不支持的文件类型: $MIME"
                exit 1
                ;;
        esac
        ;;
    
    *)
        echo "用法: multimodal.sh <action> <file> [prompt]"
        echo "Actions: image, ocr, audio, video, describe"
        exit 1
        ;;
esac

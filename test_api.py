from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'service': 'network-templates-api'}), 200

@app.route('/api/v1/network-templates/updated', methods=['POST'])
def handle_template_update():
    # Verify authorization
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    if token != 'secret-token':
        return jsonify({'error': 'Unauthorized'}), 401
    
    # Process the payload
    data = request.json
    print(f"Template updated: {data['changed_files']}")
    
    # Your business logic here
    # - Update CMS
    # - Trigger workflows
    # - Send notifications
    # etc.
    
    return jsonify({'status': 'success', 'message': 'Template update processed'})

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5001))
    app.run(debug=True, host='0.0.0.0', port=port)
# Updated

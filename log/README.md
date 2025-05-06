# logs for climate-dashboard-app

Here are the latest output log files:

<!-- Jekyll render any text (*.txt) web (*.html) files -->
{% for file in site.static_files %}
  {% if file.extname == '.html' or file.extname == '.txt' %}
* [{{ file.basename }}]({{ site.baseurl }}{{ file.path }}) ({{ file.modified_time | date: "%Y-%m-%d %H:%M" }}) 
  {% endif %}
{% endfor %}



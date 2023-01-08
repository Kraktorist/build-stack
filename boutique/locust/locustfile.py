import base64

from locust import HttpUser, TaskSet, task
from random import choice

import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class UserTasks(TaskSet):

    def on_start(self):
        """ on_start is called when a Locust start before any task is scheduled """
        self.client.verify = False

    @task
    def load(self):
        base64string = base64.b64encode(b'user:password').decode("utf-8") 
        catalogue = self.client.get("/catalogue").json()
        category_item = choice(catalogue)
        item_id = category_item["id"]
        self.client.get("/")
        self.client.get("/login", headers={"Authorization":"Basic %s" % base64string})
        self.client.get("/category.html")
        self.client.get("/detail.html?id={}".format(item_id))
        self.client.delete("/cart")
        self.client.post("/cart", json={"id": item_id, "quantity": 1})
        self.client.get("/basket.html")
        self.client.post("/orders")


class WebsiteUser(HttpUser):
    tasks = [UserTasks]
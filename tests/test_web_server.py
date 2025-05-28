import os
import pytest
import httpx
from testcontainers.core.container import DockerContainer
from testcontainers.core.waiting_utils import wait_for_logs

def image_name():
  return os.environ.get("IMAGE_UNDER_TEST_NAME", "registry.local:5000/workflows-testbed-python/testbed-python:latest")

server = DockerContainer(image_name()).with_exposed_ports(8000)

@pytest.fixture(scope="module", autouse=True)
def setup(request):
    server.start()
    wait_for_logs(server, ".*Application startup complete.*")

    def remove_container():
        server.stop()

    request.addfinalizer(remove_container)


@pytest.mark.e2e
def test_connection():
    # Given

    # When
    r = httpx.get('http://localhost:' + server.get_exposed_port(8000))

    # Then
    assert r.status_code == 200
    assert r.text == "{\"Hello\":\"World\"}"


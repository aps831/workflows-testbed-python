import pg8000
import pytest
from testcontainers.postgres import PostgresContainer

postgres = PostgresContainer("postgres:16-alpine")


@pytest.fixture(scope="module", autouse=True)
def setup(request):
    postgres.start()

    def remove_container():
        postgres.stop()

    request.addfinalizer(remove_container)


def get_local_conn(username, password):
    conn = pg8000.dbapi.connect(
        username,
        host=postgres.get_container_host_ip(),
        database=postgres.dbname,
        port=postgres.get_exposed_port(5432),
        password=password,
    )
    conn.autocommit = True
    return conn


@pytest.mark.slow
def test_connection():
    try:
        # when
        conn = get_local_conn(postgres.username, postgres.password)
        conn.close()
    except:
        # then
        pytest.fail("Unable to connect to database")

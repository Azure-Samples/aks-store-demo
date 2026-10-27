"""Compatibility checks for the image API and its installed image codec."""

import base64
from io import BytesIO
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from main import app
from routers import image_generator


@pytest.fixture
def image_environment(monkeypatch):
    """Configure a fake image deployment without loading local credentials."""
    monkeypatch.setenv("AZURE_OPENAI_IMAGE_ENDPOINT", "https://example.invalid/")
    monkeypatch.setenv("AZURE_OPENAI_IMAGE_DEPLOYMENT_NAME", "test-image")
    monkeypatch.setenv("OPENAI_API_KEY", "test-only-not-a-real-key")
    monkeypatch.setenv("USE_AZURE_AD", "false")
    monkeypatch.setattr(image_generator, "load_dotenv", lambda **kwargs: None)


def test_health_advertises_configured_image_generation(image_environment):
    """Startup exposes the configured image capability."""
    with TestClient(app) as client:
        response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert "image" in response.json()["capabilities"]


@pytest.mark.parametrize("mode,color", [("RGB", (12, 34, 56)), ("RGBA", (12, 34, 56, 78))])
def test_image_response_preserves_png(monkeypatch, image_environment, mode, color):
    """The real route preserves decodable PNG pixels from the mocked SDK."""
    with BytesIO() as buffer:
        with Image.new(mode, (2, 2), color) as source:
            source.save(buffer, format="PNG")
        png = buffer.getvalue()
    encoded = base64.b64encode(png).decode("ascii")
    sdk = Mock()
    sdk.images.generate.return_value = SimpleNamespace(
        data=[SimpleNamespace(b64_json=encoded)]
    )
    factory = Mock(return_value=sdk)
    monkeypatch.setattr(image_generator, "AzureOpenAI", factory)

    with TestClient(app) as client:
        response = client.post(
            "/generate/image",
            json={"name": "Pet bowl", "description": "Blue ceramic bowl"},
        )

    assert response.status_code == 200
    assert response.json()["image"] == f"data:image/png;base64,{encoded}"
    sdk.images.generate.assert_called_once_with(
        model="test-image",
        prompt=image_generator.USER_PROMPT_TEMPLATE.format(
            name="Pet bowl", description="Blue ceramic bowl"
        ),
        n=1,
        size="1024x1024",
        quality="high",
        output_format="png",
    )
    returned_png = base64.b64decode(response.json()["image"].split(",", 1)[1], validate=True)
    with Image.open(BytesIO(returned_png)) as decoded:
        decoded.load()
        assert decoded.format == "PNG"
        assert decoded.size == (2, 2)
        assert decoded.getpixel((0, 0)) == color

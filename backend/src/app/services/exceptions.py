class NaoEncontradoError(Exception):
    """O registro solicitado não existe. A API converte em HTTP 404."""


class ConflitoError(Exception):
    """A operação viola uma regra de unicidade. A API converte em HTTP 409."""

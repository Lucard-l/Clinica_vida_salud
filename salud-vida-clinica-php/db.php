<?php
// Salud Vida — conexión única y consultas seguras.
$config = require __DIR__ . '/config.php';
$dsn = "mysql:host={$config['host']};port={$config['port']};dbname={$config['database']};charset={$config['charset']}";
try {
    $pdo = new PDO($dsn, $config['username'], $config['password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    exit('No se pudo conectar a Salud_y_vida. Revisa config.php y que MySQL esté activo en XAMPP.');
}

function e(?string $value): string { return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8'); }
function go(string $url = 'index.php'): never { header('Location: ' . $url); exit; }
function require_login(): void { if (empty($_SESSION['user'])) go('index.php'); }
function can(array $roles): bool { $current=$_SESSION['user']['rol'] ?? ''; if($current==='SUPERVISOR' && !in_array('ADMINISTRADOR',$roles,true)) return true; return in_array($current,$roles,true); }
function flash(string $type, string $message): void { $_SESSION['flash'] = [$type, $message]; }
function take_flash(): ?array { $flash = $_SESSION['flash'] ?? null; unset($_SESSION['flash']); return $flash; }

<?php

namespace App\Jobs\Traits;

trait UsesCommandLine
{

    /**
     * @var string[]
     */
    private array $command;

    protected function initCommand(string ...$base): self
    {
        $this->command = [...$base];

        return $this;
    }

    protected function optionalParameter(string $name, mixed $value): self
    {
        if ($value) {
            $this->parameters($name, $value);
        }

        return $this;
    }

    protected function parameters(mixed ...$parameters): self
    {
        $this->command = [...$this->command, ...$parameters];

        return $this;
    }

    protected function booleanParameter(string $name, bool $value, string $true = 'yes', string $false = 'no'): self
    {
        return $this->parameters($name, $value ? $true : $false);
    }

    protected function command(): array
    {
        return $this->command;
    }

}